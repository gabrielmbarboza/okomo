# Documentação de Modelo de Dados

## Propósito

Esta documentação descreve a estrutura e os relacionamentos das entidades de dados do Okomo em diferentes níveis de abstração. O objetivo é fornecer uma visão clara da organização dos dados, facilitando:

- Revisões arquitetônicas
- Implementação de migrações de banco de dados
- Onboarding de novos desenvolvedores
- Discussões sobre modelagem entre bounded contexts
- Visualização de relacionamentos complexos

## 🎯 Comece por Aqui: Visão Global

Para uma compreensão rápida do modelo de dados em toda a plataforma:

- **[Visão Global do Modelo](overview.md)**: Documento estratégico descrevendo todos os Bounded Contexts, entidades principais e relacionamentos entre contextos.
- **[Diagrama DBML Global](dbdiagram/okomo_overview.dbml)**: Diagrama consolidado com visão de alto nível de toda a arquitetura. **Visualize em [dbdiagram.io](https://dbdiagram.io/)**.

Este é o melhor ponto de partida para novo desenvolvedores ou antes de iniciar uma grande mudança de arquitetura.

---

## Níveis de Modelagem

### Modelo Conceitual

O **modelo conceitual** descreve entidades e relacionamentos de negócio de forma independente de tecnologia. Foca em **o que** o sistema armazena do ponto de vista do domínio.

**Arquivo:** `conceptual_model.md`

### Modelo Lógico

O **modelo lógico** detalha tabelas, colunas, tipos de dados, constraints e índices específicos do PostgreSQL. Representa **como** os dados serão estruturados no banco de dados relacional.

**Arquivo:** `logical_model.md`

### Modelo Físico

O **modelo físico** seria a implementação real no banco de dados (migrações Rails, SQL DDL). Este não está incluído nesta documentação, pois é gerado através de migrações Rails.

## Relação entre Entidades de Domínio e Tabelas

As entidades de domínio (classes Ruby em `app/domains/*/entities/`) podem ou não corresponder diretamente a tabelas de banco de dados:

- **Entidades persistidas:** Mapeadas para tabelas (exemplo: `User` → `users`)
- **Value Objects:** Podem ser armazenados em colunas JSONB ou normalizados em tabelas relacionadas
- **Agregados:** Um agregado pode utilizar múltiplas tabelas
- **Entidades transientes:** Não persistidas no banco (exemplo: `Orders::ValueObjects::Money`)

## Estrutura de Diretórios

```
docs/data_model/
├── README.md                    # Este arquivo
├── overview.md                  # 🎯 Visão global consolidada de todos os contextos
├── conceptual_model.md          # Modelo conceitual (domínio)
├── logical_model.md             # Modelo lógico (PostgreSQL)
├── naming_conventions.md        # Convenções de nomenclatura
└── dbdiagram/
    ├── okomo_overview.dbml      # 🎯 Diagrama DBML global consolidado
    ├── identity.dbml            # Diagramas DBML para Identity
    ├── orders.dbml              # (futuro) Diagramas DBML para Orders
    ├── inventory.dbml           # (futuro) Diagramas DBML para Inventory
    ├── payments.dbml            # (futuro) Diagramas DBML para Payments
    └── shipping.dbml            # (futuro) Diagramas DBML para Shipping
```

## Usando DBML com dbdiagram.io

### O que é DBML?

**DBML** (Database Markup Language) é uma linguagem simples para descrever estruturas de banco de dados. É especialmente útil para criar diagramas interativos sem escrever SQL puro.

### Como Visualizar

1. Acesse [dbdiagram.io](https://dbdiagram.io/)
2. Clique em "New Diagram"
3. Copie o conteúdo do arquivo `.dbml` desejado
4. Cole no editor
5. O diagrama será gerado automaticamente

### Exemplo de Uso

Para visualizar o modelo da Identity:

1. Acesse [dbdiagram.io](https://dbdiagram.io/)
2. Cole o conteúdo de `docs/data_model/dbdiagram/identity.dbml`
3. Veja o diagrama com relacionamentos, constraints e cardinalidades

### Sintaxe Básica

```dbml
Table users {
  id uuid [pk]
  name varchar
  email varchar [unique, not null]
  privacy_policy_accepted_at timestamp
  terms_accepted_at timestamp
  consent_version varchar
  anonymized_at timestamp
  created_at timestamp [not null]
  updated_at timestamp [not null]
}

Table user_roles {
  user_id uuid [not null]
  role_id uuid [not null]
  
  indexes {
    (user_id, role_id) [unique]
  }
}

Ref: users.id < user_roles.user_id
```

Para LGPD, `deleted_at` é apenas uma ferramenta técnica. O modelo deve preferir `anonymized_at` e anonimização seletiva para remover ou substituir dados pessoais sem quebrar histórico transacional.

## Relacionamento entre Diagramas Global e Específicos

### Diagrama Global (`okomo_overview.dbml`)

O diagrama global oferece uma visão **arquitetônica consolidada** de todos os Bounded Contexts. É útil para:

- **Comunicação entre domínios**: Entender como um contexto se integra com outros
- **Planejamento de features**: Identificar impactos em cascata
- **Onboarding**: Visão rápida da plataforma
- **Revisões de arquitetura**: Validar decisões de design

### Diagramas Específicos (`identity.dbml`, `orders.dbml`, etc.)

Cada Bounded Context tem seu próprio diagrama DBML com **detalhes completos**:
- Todas as colunas e tipos de dados
- Constraints e índices detalhados
- Relacionamentos internos do contexto
- Decisões de design e notas técnicas

**Filosofia:** O modelo de dados é tratado como um artefato evolutivo. O diagrama global fornece a "bússola arquitetônica", enquanto diagramas específicos refletem a realidade implementada e evoluem incrementalmente.

Para detalhes completos, consulte `naming_conventions.md`.

**Resumo rápido:**

- Tabelas: `snake_case` (plural): `users`, `user_roles`
- Colunas: `snake_case`: `email`, `created_at`, `user_id`
- Chaves primárias: `id` (UUID)
- Chaves estrangeiras: `{tabela_singular}_id`: `user_id`, `role_id`
- Timestamps: `created_at`, `updated_at`
- Soft deletes: `deleted_at`
- Anonimização LGPD: `anonymized_at`
- Status/Enums: `varchar` com valores em UPPERCASE

## Contextos de Domínio Cobertos

### Identity (Primeira Prioridade)

Gerencia usuários, autenticação, autorização e perfis de vendedor.

**Tabelas:**
- `users`
- `roles`
- `user_roles`
- `seller_profiles`
- `email_confirmation_tokens`
- `password_reset_tokens`

**Arquivo DBML:** `dbdiagram/identity.dbml`

### Outros Contextos (Em Desenvolvimento)

- **Orders:** Gerenciamento de pedidos e itens
- **Inventory:** Controle de produtos e variantes
- **Payments:** Processamento de pagamentos
- **Shipping:** Gerenciamento de envios
- **Catalog:** Catálogo de produtos e categorias

Cada contexto terá seu próprio arquivo DBML quando as decisões de design forem finalizadas.

## Mantendo Esta Documentação Atualizada

1. **Quando adicionar uma nova tabela:**
   - Atualize `logical_model.md` com a descrição
   - Atualize o arquivo `.dbml` correspondente
   - Adicione regras de negócio ao `conceptual_model.md`

2. **Quando modificar uma tabela:**
   - Documente a mudança em `logical_model.md`
   - Atualize o arquivo `.dbml`
   - Crie uma migração Rails em `db/migrate/`

3. **Quando adicionar um novo bounded context:**
   - Crie um novo arquivo `.dbml` em `dbdiagram/`
   - Documente entidades e relacionamentos
   - Atualize esta seção de índice

## Referências

- [DBML Documentation](https://www.dbml.org/)
- [dbdiagram.io](https://dbdiagram.io/)
- [PostgreSQL Documentation](https://www.postgresql.org/docs/)
- [Rails Migrations](https://guides.rubyonrails.org/active_record_migrations.html)
