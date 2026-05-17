# Modelo Lógico — Identity

## Visão Geral

O modelo lógico descreve a implementação no PostgreSQL do modelo conceitual. Inclui tipos de dados específicos, constraints, índices e detalhes técnicos da realização das entidades em tabelas relacionais.

## Tabelas

### users

**Propósito:** Armazenar dados de usuários e estado de autenticação.

| Coluna | Tipo | Null | Padrão | Comentários |
|--------|------|------|--------|------------|
| id | uuid | NOT NULL | gen_random_uuid() | Chave primária, gerada automaticamente |
| name | varchar(255) | NULL | | Nome do usuário |
| email | varchar(254) | NOT NULL | | Email único, formato RFC 5321 |
| password_digest | varchar(255) | NOT NULL | | Hash bcrypt da senha |
| status | varchar(50) | NOT NULL | 'pending_confirmation' | Enum: pending_confirmation, active, blocked, deactivated |
| email_confirmed_at | timestamp | NULL | | NULL até confirmação |
| last_login_at | timestamp | NULL | | Rastreia último acesso |
| terms_accepted_at | timestamp | NULL | | Aceite dos Termos de Uso |
| privacy_policy_accepted_at | timestamp | NULL | | Aceite da Política de Privacidade |
| consent_version | varchar(50) | NULL | | Versão dos documentos aceitos |
| consent_ip_address | inet | NULL | | IP usado no aceite, quando necessário |
| consent_user_agent | text | NULL | | User-Agent usado no aceite, quando necessário |
| blocked_at | timestamp | NULL | | Data de bloqueio |
| deactivated_at | timestamp | NULL | | Data de desativação |
| anonymized_at | timestamp | NULL | | Data de anonimização seletiva |
| deleted_at | timestamp | NULL | | Soft delete técnico, quando aplicável |
| created_at | timestamp | NOT NULL | CURRENT_TIMESTAMP | Data de criação |
| updated_at | timestamp | NOT NULL | CURRENT_TIMESTAMP | Data da última atualização |

**Constraints:**
- PRIMARY KEY: `id`
- UNIQUE: `email`
- CHECK: `status IN ('pending_confirmation', 'active', 'blocked', 'deactivated')`
- CHECK: `LENGTH(email) <= 254 AND email LIKE '%@%.%'`
- CHECK: `(status = 'blocked' AND blocked_at IS NOT NULL) OR status != 'blocked'`
- CHECK: `(status = 'deactivated' AND deactivated_at IS NOT NULL) OR status != 'deactivated'`
- CHECK: `(terms_accepted_at IS NOT NULL AND privacy_policy_accepted_at IS NOT NULL AND consent_version IS NOT NULL) OR anonymized_at IS NOT NULL`

**Índices:**
- PRIMARY: `users_pkey` (id)
- UNIQUE: `users_email_idx` (email)
- REGULAR: `users_status_idx` (status)
- REGULAR: `users_created_at_idx` (created_at)
- REGULAR: `users_anonymized_at_idx` (anonymized_at)
- REGULAR: `users_deleted_at_idx` (deleted_at)
- REGULAR: `users_consent_version_idx` (consent_version)

**Triggers:**
- Atualiza `updated_at` automaticamente em UPDATE

---

### roles

**Propósito:** Armazenar papéis/permissões disponíveis no sistema.

| Coluna | Tipo | Null | Padrão | Comentários |
|--------|------|------|--------|------------|
| id | uuid | NOT NULL | gen_random_uuid() | Chave primária |
| name | varchar(50) | NOT NULL | | Nome único: buyer, seller, platform_admin |
| description | text | NULL | | Descrição das responsabilidades |
| created_at | timestamp | NOT NULL | CURRENT_TIMESTAMP | Data de criação |
| updated_at | timestamp | NOT NULL | CURRENT_TIMESTAMP | Data da última atualização |

**Constraints:**
- PRIMARY KEY: `id`
- UNIQUE: `name`
- CHECK: `LENGTH(name) > 0`

**Índices:**
- PRIMARY: `roles_pkey` (id)
- UNIQUE: `roles_name_idx` (name)

**Dados Iniciais (Seed):**
```
buyer      | Pode comprar na plataforma
seller     | Pode vender na plataforma
platform_admin  | Pode revisar perfis, moderar vendedores e administrar a plataforma
```

---

### user_roles

**Propósito:** Relacionamento auditável muitos-para-muitos entre usuários e roles.

| Coluna | Tipo | Null | Padrão | Comentários |
|--------|------|------|--------|------------|
| id | uuid | NOT NULL | gen_random_uuid() | Chave primária |
| user_id | uuid | NOT NULL | | FK → users(id) |
| role_id | uuid | NOT NULL | | FK → roles(id) |
| granted_at | timestamp | NOT NULL | CURRENT_TIMESTAMP | Data de concessão |
| revoked_at | timestamp | NULL | | NULL enquanto ativo |
| granted_by_user_id | uuid | NULL | | FK → users(id), admin que concedeu |
| revoked_by_user_id | uuid | NULL | | FK → users(id), admin que revogou |
| reason | text | NULL | | Motivo da concessão ou revogação |
| created_at | timestamp | NOT NULL | CURRENT_TIMESTAMP | Data de criação |
| updated_at | timestamp | NOT NULL | CURRENT_TIMESTAMP | Data da última atualização |

**Constraints:**
- PRIMARY KEY: `id`
- FOREIGN KEY: `user_id` REFERENCES `users(id)` ON DELETE RESTRICT
- FOREIGN KEY: `role_id` REFERENCES `roles(id)` ON DELETE RESTRICT
- FOREIGN KEY: `granted_by_user_id` REFERENCES `users(id)` ON DELETE SET NULL
- FOREIGN KEY: `revoked_by_user_id` REFERENCES `users(id)` ON DELETE SET NULL
- CHECK: `user_id IS NOT NULL AND role_id IS NOT NULL`
- CHECK: `revoked_at IS NULL OR revoked_at >= granted_at`

**Índices:**
- PRIMARY: `user_roles_pkey` (id)
- REGULAR: `user_roles_user_id_role_id_idx` (user_id, role_id)
- PARTIAL UNIQUE: `user_roles_active_role_idx` (user_id, role_id) WHERE `revoked_at IS NULL`
- REGULAR: `user_roles_user_id_idx` (user_id)
- REGULAR: `user_roles_role_id_idx` (role_id)
- REGULAR: `user_roles_revoked_at_idx` (revoked_at)
- REGULAR: `user_roles_granted_by_user_id_idx` (granted_by_user_id)
- REGULAR: `user_roles_revoked_by_user_id_idx` (revoked_by_user_id)

---

### seller_profiles

**Propósito:** Armazenar perfis de vendedor e processo de aprovação.

| Coluna | Tipo | Null | Padrão | Comentários |
|--------|------|------|--------|------------|
| id | uuid | NOT NULL | gen_random_uuid() | Chave primária |
| user_id | uuid | NOT NULL | | FK → users(id), UNIQUE |
| display_name | varchar(255) | NOT NULL | | Nome público do vendedor |
| description | text | NULL | | Descrição da loja |
| status | varchar(50) | NOT NULL | 'pending_review' | Enum: pending_review, approved, rejected, suspended |
| requested_at | timestamp | NOT NULL | CURRENT_TIMESTAMP | Data da solicitação |
| reviewed_at | timestamp | NULL | | Data da revisão |
| reviewed_by_user_id | uuid | NULL | | FK → users(id), User com role `platform_admin` |
| rejection_reason | text | NULL | | Motivo se rejeitado |
| approved_at | timestamp | NULL | | Data da aprovação |
| rejected_at | timestamp | NULL | | Data da rejeição |
| suspended_at | timestamp | NULL | | Data da suspensão |
| suspension_reason | text | NULL | | Motivo da suspensão |
| created_at | timestamp | NOT NULL | CURRENT_TIMESTAMP | Data de criação |
| updated_at | timestamp | NOT NULL | CURRENT_TIMESTAMP | Data da última atualização |

**Constraints:**
- PRIMARY KEY: `id`
- FOREIGN KEY: `user_id` REFERENCES `users(id)` ON DELETE RESTRICT
- FOREIGN KEY: `reviewed_by_user_id` REFERENCES `users(id)` ON DELETE SET NULL
- UNIQUE: `user_id`
- CHECK: `status IN ('pending_review', 'approved', 'rejected', 'suspended')`
- CHECK: `LENGTH(display_name) > 0`
- CHECK: `(status = 'rejected' AND rejection_reason IS NOT NULL) OR status != 'rejected'`
- CHECK: `(status = 'approved' AND approved_at IS NOT NULL) OR status != 'approved'`

**Índices:**
- PRIMARY: `seller_profiles_pkey` (id)
- UNIQUE: `seller_profiles_user_id_idx` (user_id)
- REGULAR: `seller_profiles_status_idx` (status)
- REGULAR: `seller_profiles_requested_at_idx` (requested_at)
- REGULAR: `seller_profiles_reviewed_by_user_id_idx` (reviewed_by_user_id)

---

### email_confirmation_tokens

**Propósito:** Tokens temporários para confirmar propriedade de email.

| Coluna | Tipo | Null | Padrão | Comentários |
|--------|------|------|--------|------------|
| id | uuid | NOT NULL | gen_random_uuid() | Chave primária |
| user_id | uuid | NOT NULL | | FK → users(id) |
| token_digest | varchar(255) | NOT NULL | | SHA256 do token (nunca armazenar token em texto plano) |
| expires_at | timestamp | NOT NULL | | Token expira após X horas (ex: 24h) |
| used_at | timestamp | NULL | | NULL até ser utilizado |
| created_at | timestamp | NOT NULL | CURRENT_TIMESTAMP | Data de criação |

**Constraints:**
- PRIMARY KEY: `id`
- FOREIGN KEY: `user_id` REFERENCES `users(id)` ON DELETE CASCADE
- UNIQUE: `token_digest`
- CHECK: `expires_at > created_at`
- CHECK: `used_at IS NULL OR used_at >= created_at`

**Índices:**
- PRIMARY: `email_confirmation_tokens_pkey` (id)
- UNIQUE: `email_confirmation_tokens_token_digest_idx` (token_digest)
- REGULAR: `email_confirmation_tokens_user_id_idx` (user_id)
- REGULAR: `email_confirmation_tokens_expires_at_idx` (expires_at)
- REGULAR: `email_confirmation_tokens_used_at_idx` (used_at) - Para limpeza

**Cleanup:**
- Tokens expirados e não utilizados devem ser removidos (job agendado)
- Query: `DELETE FROM email_confirmation_tokens WHERE expires_at < NOW() AND used_at IS NULL`

---

### password_reset_tokens

**Propósito:** Tokens temporários para reset de senha.

| Coluna | Tipo | Null | Padrão | Comentários |
|--------|------|------|--------|------------|
| id | uuid | NOT NULL | gen_random_uuid() | Chave primária |
| user_id | uuid | NOT NULL | | FK → users(id) |
| token_digest | varchar(255) | NOT NULL | | SHA256 do token |
| expires_at | timestamp | NOT NULL | | Token expira após X horas (ex: 2h) |
| used_at | timestamp | NULL | | NULL até ser utilizado |
| created_at | timestamp | NOT NULL | CURRENT_TIMESTAMP | Data de criação |

**Constraints:**
- PRIMARY KEY: `id`
- FOREIGN KEY: `user_id` REFERENCES `users(id)` ON DELETE CASCADE
- UNIQUE: `token_digest`
- CHECK: `expires_at > created_at`
- CHECK: `used_at IS NULL OR used_at >= created_at`

**Índices:**
- PRIMARY: `password_reset_tokens_pkey` (id)
- UNIQUE: `password_reset_tokens_token_digest_idx` (token_digest)
- REGULAR: `password_reset_tokens_user_id_idx` (user_id)
- REGULAR: `password_reset_tokens_expires_at_idx` (expires_at)
- REGULAR: `password_reset_tokens_used_at_idx` (used_at) - Para limpeza

**Cleanup:**
- Tokens expirados e utilizados devem ser removidos (job agendado)
- Query: `DELETE FROM password_reset_tokens WHERE expires_at < NOW() OR used_at IS NOT NULL`

---

## Resumo de Relacionamentos

```
users (1) ──────┬──── (N) user_roles ──── (1) roles
               │
               ├──── (0..1) seller_profiles
               │
               ├──── (1) ←─── (N) seller_profiles (reviewed_by_user_id)
               │
               ├──── (N) email_confirmation_tokens
               │
               └──── (N) password_reset_tokens
```

## Tipo de Dados Específicos

### UUID (Universally Unique Identifier)

Tipo nativo do PostgreSQL para chaves primárias únicas globalmente.

```sql
id uuid PRIMARY KEY DEFAULT gen_random_uuid()
```

**Vantagens:**
- Distribuído (gerado no cliente/servidor, não sequencial)
- Imutável
- Globalmente único
- Adequado para replicação

### VARCHAR com LIMIT

```sql
email varchar(254) NOT NULL  -- RFC 5321 máximo
```

### TIMESTAMP

```sql
created_at timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP
```

**Notas:**
- PostgreSQL armazena sem fuso horário (UTC recomendado)
- Rails configura automaticamente

### ENUM ou VARCHAR

Este projeto usa `VARCHAR` para status/roles, não enum do PostgreSQL:

**Motivo:** Flexibilidade de adicionar valores sem ALTER TABLE.

```sql
status varchar(50) NOT NULL CHECK (status IN (...))
```

## Política de Cascata e Restrições

### DELETE CASCADE

Aplicado quando:
- `email_confirmation_tokens` referencia `users` - Remoção técnica controlada de user remove tokens temporários
- `password_reset_tokens` referencia `users` - Remoção técnica controlada de user remove tokens temporários

### DELETE RESTRICT

Aplicado quando:
- `user_roles` referencia `roles` - Não pode deletar role com usuários
- `user_roles` referencia `users` - Histórico de roles não deve ser apagado por exclusão física acidental
- `seller_profiles` referencia `users` - Perfil de seller precisa ser tratado por anonimização/retention policy
- `orders`, `payments` e registros históricos referenciam `users` - Retenção legal e transacional prevalece

### DELETE SET NULL

Aplicado quando:
- `seller_profiles.reviewed_by_user_id` referencia `users` - User revisor removido não anula histórico

## Estratégia de Índices

### Índices Obrigatórios

1. **Chaves Primárias:** Automático
2. **Chaves Estrangeiras:** Para performance de JOINs
3. **UNIQUE:** Para constraints de unicidade

### Índices Recomendados

1. **email** em `users` - Buscas por email
2. **status** em `users` e `seller_profiles` - Filtros por status
3. **created_at** em `users` - Ordenação por data
4. **(user_id, role_id)** em `user_roles` - Queries de autorização
5. **expires_at** em `*_tokens` - Limpeza e validação

### Queries de Performance

```sql
-- Encontrar usuário com roles (típico)
SELECT u.*, r.name FROM users u
JOIN user_roles ur ON u.id = ur.user_id
JOIN roles r ON ur.role_id = r.id
WHERE u.email = 'user@example.com';

-- Encontrar perfis pendentes (típico)
SELECT * FROM seller_profiles
WHERE status = 'pending_review'
ORDER BY requested_at ASC;

-- Validar token (crítico para performance)
SELECT * FROM email_confirmation_tokens
WHERE token_digest = $1 AND expires_at > NOW() AND used_at IS NULL;
```

## Integridade Referencial

Todas as foreign keys incluem:
- Política adequada (CASCADE, SET NULL, RESTRICT)
- Índice automático no PostgreSQL para otimização

Exemplo de migração:
```ruby
add_foreign_key :user_roles, :users, on_delete: :cascade
add_foreign_key :user_roles, :roles, on_delete: :restrict
```

## Versionamento e Evolução

Este modelo pode evoluir quando:
- Novos requisitos de autenticação surgirem
- Roles adicionais forem necessárias
- Policies complexas forem implementadas
- Auditoria detalhada for requerida

Cada mudança deve:
1. Gerar uma nova migração Rails
2. Atualizar documentação
3. Ser revisada arquitetonicamente
4. Ser testada em ambiente de staging

## LGPD e Retenção

O modelo lógico segue a ADR-021:

- `users.anonymized_at` é o marcador principal de anonimização seletiva;
- `deleted_at` é apenas soft delete técnico e não substitui anonimização;
- e-mail, nome, documento, telefone e endereço devem ser removidos, substituídos ou criptografados conforme política de retenção;
- registros transacionais e fiscais devem preservar integridade mesmo quando a conta for anonimizada;
- tokens temporários continuam sujeitos a limpeza agressiva por expiração/uso.
