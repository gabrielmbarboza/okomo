# ADR-018 — Roles e UserRole como Entidades Auditáveis

- **Status:** Accepted
- **Data:** 2026-05-17
- **Contexto:** Identity
- **Relacionado:** ADR-001 (Monólito Modular), ADR-013 (Identity como Bounded Context)

---

## Contexto

O Okomo requer um sistema de autorização que permita diferentes papéis de negócio:

- `buyer` - Comprador padrão que todos os usuários confirmados recebem
- `seller` - Vendedor que requer aplicação e aprovação
- `platform_admin` - Administrador da plataforma

Historicamente, o modelo poderia ter sido uma simples tabela `user_roles` de relacionamento 1:1 ou N:N. Porém, havia requisitos importantes de auditoria:

1. **Trilha de Auditoria Completa:** Precisamos saber exatamente quando cada role foi concedido e revogado
2. **Rastreamento de Quem:** Precisamos saber qual administrador fez cada concessão/revogação
3. **Histórico Imutável:** Rejeições, suspensões e reativações devem estar bem documentadas
4. **Conformidade:** LGPD exige logs auditáveis de mudanças de permissões

Um modelo simples onde roles são apenas adicionadas e removidas não forneceria essa auditoria de forma limpa.

---

## Problema

### Sem Auditoria Explícita

Se usássemos apenas uma tabela simples `user_roles`:

```sql
-- Simples, mas sem auditoria
CREATE TABLE user_roles (
  user_id UUID,
  role_id UUID,
  PRIMARY KEY (user_id, role_id)
);
```

Poderíamos:
- Saber que um usuário tem um role
- Mas **não** saber quando foi concedido
- Mas **não** saber quando foi revogado
- Mas **não** saber por qual admin
- Mas **não** saber por qual razão

Isso viola requisitos de auditoria e compliance.

### Com Auditoria Implícita (Timestamps)

Poderíamos adicionar `created_at`:

```sql
CREATE TABLE user_roles (
  user_id UUID,
  role_id UUID,
  created_at TIMESTAMP,
  PRIMARY KEY (user_id, role_id)
);
```

Mas:
- Ainda não sabemos quando foi revogado
- Ainda não sabemos por qual razão
- Ainda não sabemos quem o revogou
- Se precisarmos revogar, precisamos deletar a linha (irreversível)

---

## Decisão

Implementamos `UserRole` como uma **entidade de auditoria imutável** que registra cada mudança individual de role:

```ruby
class UserRole < ApplicationRecord
  # Auditoria:
  # - granted_at: timestamp de concessão
  # - revoked_at: null enquanto ativo, timestamp quando revogado
  # - granted_by_user_id: qual admin concedeu
  # - revoked_by_user_id: qual admin revogou
  # - reason: motivo da concessão/revogação
end
```

**Modelo de Dados:**

```sql
CREATE TABLE user_roles (
  id UUID PRIMARY KEY,
  user_id UUID NOT NULL,
  role_id UUID NOT NULL,
  granted_at TIMESTAMP NOT NULL,
  revoked_at TIMESTAMP,              -- NULL = ativo, not NULL = revogado
  granted_by_user_id UUID,           -- Qual admin concedeu
  revoked_by_user_id UUID,           -- Qual admin revogou
  reason TEXT,                       -- Motivo
  created_at TIMESTAMP NOT NULL,
  updated_at TIMESTAMP NOT NULL
);

-- Índices para query eficiente
CREATE INDEX user_roles_active ON user_roles(user_id, revoked_at) WHERE revoked_at IS NULL;
CREATE INDEX user_roles_user_id ON user_roles(user_id);
CREATE INDEX user_roles_role_id ON user_roles(role_id);
```

**Diferença Chave:**

- Um `UserRole` com `revoked_at = NULL` significa o role está **ativo**
- Um `UserRole` com `revoked_at = timestamp` significa o role foi **revogado** naquele momento
- Nunca deletamos histórico, apenas marcamos como revogado

---

## Consequências

### Positivas ✅

1. **Auditoria Completa:** Cada concessão e revogação é um registro imutável
2. **Rastreamento:** Sabemos exatamente quem fez cada mudança e por quê
3. **Compliance:** Atende requisitos de LGPD e conformidade
4. **Histórico Irreversível:** Não podemos "apagar" mudanças acidentalmente
5. **Análise Temporal:** Podemos responder "Qual era o role do user X em 2026-05-15?"
6. **Reversibilidade:** Se um role for revogado, podemos concedê-lo novamente com histórico completo

### Negativas ⚠️

1. **Mais Dados:** Armazena histórico de todas as mudanças (vs apenas estado atual)
2. **Query Mais Complexa:** Para saber roles atuais, precisamos filtrar `revoked_at IS NULL`
3. **Overhead:** Tabela cresce com cada mudança de role (mas isso é aceitável para auditoria)

### Exemplos de Cenários

**Cenário 1: User Recebe Buyer Role**

```
UserRole Record 1:
- user_id: john-uuid
- role_id: buyer-uuid
- granted_at: 2026-05-17 10:00:00
- revoked_at: NULL (ativo)
- granted_by_user_id: admin1-uuid
- reason: "automatic on email confirmation"
```

**Cenário 2: Seller Aprovado**

```
UserRole Record 2:
- user_id: jane-uuid
- role_id: seller-uuid
- granted_at: 2026-05-18 14:30:00
- revoked_at: NULL (ativo)
- granted_by_user_id: moderator-uuid
- reason: "approved seller application #12345"
```

**Cenário 3: Seller Suspenso (Role Revogado)**

```
UserRole Record 2 (mesma, agora modificada):
- user_id: jane-uuid
- role_id: seller-uuid
- granted_at: 2026-05-18 14:30:00
- revoked_at: 2026-05-20 09:15:00 (agora preenchido)
- revoked_by_user_id: moderator-uuid
- reason: "violation of seller policy - counterfeit goods"
```

**Cenário 4: Role Restaurado Após Resolução**

```
UserRole Record 3 (novo):
- user_id: jane-uuid
- role_id: seller-uuid
- granted_at: 2026-05-22 11:00:00 (nova concessão)
- revoked_at: NULL (ativo novamente)
- granted_by_user_id: moderator-uuid
- reason: "reactivated after violation resolution"
```

**Trilha de Auditoria Completa:**

```
2026-05-18: seller role concedido após aprovação
2026-05-20: seller role revogado por violação de política
2026-05-22: seller role concedido novamente após resolução

-> Temos histórico completo, imutável e rastreável
```

---

## Role `buyer` Especial

O role `buyer` é atribuído automaticamente quando um usuário confirma o e-mail:

```ruby
# Quando UserEmailConfirmed é processado:
user.grant_role(:buyer, reason: "automatic on email confirmation")
```

Uma vez concedido, **nunca pode ser revogado**:

```ruby
# Na camada de aplicação, verificamos:
if role == :buyer && attempting_to_revoke
  raise "Cannot revoke buyer role - it's fundamental to every user"
end
```

Isso garante que todo usuário confirmado permanece um buyer, mesmo se bloqueado ou deativado.

---

## Impacto na Camada de Aplicação

### Query de Roles Atuais

```ruby
# Para saber os roles ativos de um user:
current_roles = User
  .joins(:user_roles)
  .where(id: user_id)
  .where('user_roles.revoked_at IS NULL')
  .distinct
  .pluck('roles.name')
```

### Atribuição de Role

```ruby
# Conceder um role:
user.grant_role(:seller,
  granted_by: admin,
  reason: "approved seller application"
)
```

### Revogação de Role

```ruby
# Revogar um role (exceto buyer):
user.revoke_role(:seller,
  revoked_by: admin,
  reason: "violation of seller policy"
)
```

---

## Decisões de Design Relacionadas

### 1. Role é um Catálogo Global

`Role` não muda frequentemente e é um catálogo de papéis da plataforma:

```sql
INSERT INTO roles (id, name, description) VALUES
  (uuid(), 'buyer', 'Can purchase items'),
  (uuid(), 'seller', 'Can sell items'),
  (uuid(), 'platform_admin', 'Administers the platform');
```

### 2. SellerProfile é Separado

O status de seller (pending_review, approved, suspended) é gerenciado em `SellerProfile`, não em `UserRole`.

- `UserRole` apenas rastreia concessão/revogação do role `seller`
- `SellerProfile` rastreia o status da aplicação de vendedor

Isso mantém responsabilidades bem definidas.

### 3. Índice de Query Otimizado

Para performance, usamos índice em `(user_id, revoked_at)`:

```sql
CREATE INDEX user_roles_active ON user_roles(user_id, revoked_at) WHERE revoked_at IS NULL;
```

Isso permite queries rápidas de "roles atuais de um user".

---

## Alternativas Consideradas

### Alternativa 1: Simples N:N Sem Auditoria

❌ **Rejeitada:** Não atende requisitos de auditoria e compliance

### Alternativa 2: UserRole com Soft Delete

❌ **Rejeitada:** Soft delete (is_deleted flag) é menos claro que revoked_at timestamp

### Alternativa 3: Event Sourcing Puro

❌ **Considerada mas descartada por ora:** Adiciona complexidade não necessária agora. Pode evoluir para isso depois

### Alternativa 4: Histórico em Tabela Separada

❌ **Rejeitada:** Duplicação desnecessária. Um único modelo auditable é mais limpo

---

## Consequências de Longo Prazo

### Escalabilidade

Com crescimento de usuários e roles:
- Tabela `user_roles` pode crescer ~10x o tamanho de `users`
- Índice em `(user_id, revoked_at)` mantém queries eficientes
- Pode precisar de particionamento se passar de 10M+ usuários

### Conformidade

Atende:
- LGPD: Trilha de auditoria imutável
- SOC 2: Rastreamento de mudanças de permissões
- Compliance: Log auditável de ações administrativas

---

## Implementação

Esta decisão será implementada em:

1. **Migrations:** Criar tabela com estrutura auditable
2. **Entities:** `Role`, `UserRole` como entidades do domínio
3. **Use Cases:** Implementar grant/revoke de roles com auditoria
4. **Tests:** Cobertura completa de concessão, revogação, e histórico

---

## Relacionamentos

- ✅ Alinhado com **ADR-013** (Identity como BC)
- ✅ Alinhado com **ADR-012** (Criptografia de dados sensíveis para document_number)
- ✅ Alinhado com princípios de **Event Sourcing** (auditoria via eventos)
- 🔗 Prepara caminho para potencial **migração para Event Sourcing** futuro
