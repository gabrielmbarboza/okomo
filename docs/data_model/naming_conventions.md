# Convenções de Nomenclatura — Modelo de Dados

## Objetivo

Este documento estabelece convenções consistentes para nomear tabelas, colunas, índices, constraints e outros objetos de banco de dados no Okomo. Consistência facilita:

- Compreensão do código e queries
- Onboarding de novos desenvolvedores
- Manutenção de longo prazo
- Geração automática de código
- Queries intuitivas

## Tabelas

### Regra Geral

```
snake_case, plural, em inglês
```

**Exemplos:**

| Tabela | Correto | Errado |
|--------|---------|--------|
| Users | `users` | `User`, `Users`, `USERS`, `user` |
| Roles | `roles` | `Role`, `Roles`, `role_table` |
| User Roles (junção) | `user_roles` | `UserRole`, `user_role`, `users_roles` |
| Seller Profiles | `seller_profiles` | `SellerProfile`, `seller_profile`, `sellerprofiles` |
| Email Confirmation Tokens | `email_confirmation_tokens` | `EmailConfirmationToken`, `email_tokens` |

### Caso Especial: Tabelas de Junção

Tabelas de relacionamento muitos-para-muitos seguem o padrão:

```
{modelo1}_{modelo2}
```

onde os modelos estão em ordem alfabética.

**Exemplos:**

```
user_roles          # Correto (order: role < user alfabeticamente)
order_items         # Correto
product_categories  # Correto
```

**NÃO use:**

```
roles_users         # Ordem alfabética errada
user_has_roles      # Desnecessário
```

### Pluralização

Tabelas são SEMPRE plurais:

- `users` (não `user`)
- `orders` (não `order`)
- `seller_profiles` (não `seller_profile`)

**Exceção:** Tabelas de histórico/auditoria podem ser singulares se a ferramenta exigir:

- `user_audit` (singular para cada registro de auditoria)

## Colunas

### Regra Geral

```
snake_case, singular, em inglês
```

**Exemplos:**

| Campo | Correto | Errado |
|-------|---------|--------|
| Nome do usuário | `name` | `user_name`, `userName`, `fullName` |
| Email | `email` | `user_email`, `email_address` |
| Status | `status` | `user_status`, `stat` |
| Criado em | `created_at` | `createdAt`, `created_date`, `creation_date` |

### Chaves Primárias

```
id
```

Sempre chamada `id`, tipo `uuid`.

```sql
id uuid PRIMARY KEY DEFAULT gen_random_uuid()
```

**Nunca use:**

```
user_id         # Apenas para foreign keys
pk_id
identifier
```

### Chaves Estrangeiras

```
{tabela_singular}_id
```

Referência a tabela `users`:
```
user_id
```

Referência a tabela `roles`:
```
role_id
```

Referência a tabela `seller_profiles`:
```
seller_profile_id
```

**Exemplo Completo:**

```sql
CREATE TABLE orders (
  id uuid PRIMARY KEY,
  user_id uuid NOT NULL REFERENCES users(id),  -- OK
  seller_id uuid NOT NULL REFERENCES users(id) -- OK (diferente chave estrangeira)
);
```

### Timestamps

```
created_at   -- Quando foi criado
updated_at   -- Quando foi atualizado
deleted_at   -- Quando foi deletado (soft delete)
{ação}_at    -- Timestamps específicos de ação
```

**Exemplos:**

```sql
created_at timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP
updated_at timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP
deleted_at timestamp NULL
email_confirmed_at timestamp NULL
approved_at timestamp NULL
suspended_at timestamp NULL
last_login_at timestamp NULL
```

**Nunca use:**

```
created_on          -- Use _at
creation_date       -- Use _at
updated_date        -- Use _at
created_timestamp   -- Use _at
```

### Booleans

Use `BOOLEAN` do PostgreSQL ou `VARCHAR(50)` para enums mais complexos:

**Simples (boolean):**

```sql
is_active boolean DEFAULT true
is_admin boolean DEFAULT false
```

**Complexo (enum/varchar):**

```sql
status varchar(50) NOT NULL  -- pending_review, approved, rejected
```

**Nunca use:**

```
active_flag       -- Use is_active
admin_b           -- Abreviações são ruins
has_email         -- Prefira is_email_confirmed
```

### Digests e Hashes

Colunas que armazenam hashes nunca armazenam o valor original:

```
password_digest        -- Hash da senha (bcrypt)
token_digest           -- Hash do token
```

**Nunca use:**

```
password_hash   -- Não é suficientemente descritivo
token           -- Nunca armazene em texto plano
```

## Constraints

### Unique Constraints

```
{tabela}_{coluna(s)}_unique
```

**Exemplos:**

```sql
ALTER TABLE users ADD CONSTRAINT users_email_unique UNIQUE (email);
ALTER TABLE user_roles ADD CONSTRAINT user_roles_unique UNIQUE (user_id, role_id);
```

### Foreign Keys

Nomeação automática pelo PostgreSQL é geralmente aceitável:

```
{tabela}_tabela_referenciada_fk
```

Se você quiser nomear explicitamente:

```sql
ALTER TABLE orders 
  ADD CONSTRAINT orders_user_id_fk 
  FOREIGN KEY (user_id) REFERENCES users(id);
```

### Check Constraints

```
{tabela}_{coluna}_check
```

**Exemplos:**

```sql
ALTER TABLE users 
  ADD CONSTRAINT users_status_check 
  CHECK (status IN ('pending_confirmation', 'active', 'suspended'));

ALTER TABLE seller_profiles 
  ADD CONSTRAINT seller_profiles_status_check 
  CHECK (status IN ('pending_review', 'approved', 'rejected'));
```

## Índices

### Chaves Primárias

PostgreSQL cria automaticamente:

```
{tabela}_pkey
```

### Índices UNIQUE

```
{tabela}_{coluna(s)}_idx
```

**Exemplos:**

```sql
CREATE UNIQUE INDEX users_email_idx ON users(email);
CREATE UNIQUE INDEX user_roles_user_id_role_id_idx ON user_roles(user_id, role_id);
```

### Índices Regulares

```
{tabela}_{coluna(s)}_idx
```

**Exemplos:**

```sql
CREATE INDEX users_status_idx ON users(status);
CREATE INDEX seller_profiles_requested_at_idx ON seller_profiles(requested_at);
CREATE INDEX email_confirmation_tokens_expires_at_idx ON email_confirmation_tokens(expires_at);
```

### Índices Compostos

A ordem importa! Prefira ordem utilizada em queries:

```sql
-- Bom: usado em WHERE user_id AND role_id
CREATE INDEX user_roles_user_id_role_id_idx ON user_roles(user_id, role_id);

-- Menos ideal: ordem oposta
CREATE INDEX user_roles_role_id_user_id_idx ON user_roles(role_id, user_id);
```

## Enums / Valores de Status

Valores de status são sempre:
- Lowercase com underscores
- Em inglês
- Armazenados como `VARCHAR`

### Status de User

```
pending_confirmation   -- Email não confirmado
active                 -- Ativo e autenticado
suspended              -- Temporariamente bloqueado
deleted                -- Soft-delete
```

### Status de SellerProfile

```
pending_review         -- Aguardando revisão
approved               -- Aprovado
rejected               -- Rejeitado
suspended              -- Suspenso por violação
```

### Status Genéricos

```
pending       -- Aguardando ação
active        -- Ativo
inactive      -- Inativo
archived      -- Arquivado
deleted       -- Deletado (soft-delete)
```

## Tipos de Dados

### Strings

- **email:** `varchar(254)` - RFC 5321
- **name, display_name, description:** `varchar(255)` ou `text`
- **password_digest, token_digest:** `varchar(255)` - Para hashes
- **status, enum:** `varchar(50)`

### Identificadores

- **id (primary key):** `uuid DEFAULT gen_random_uuid()`
- **foreign keys:** `uuid NOT NULL`

### Timestamps

- **created_at, updated_at:** `timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP`
- **{ação}_at:** `timestamp NULL`

### Booleans

- **flags simples:** `boolean DEFAULT false`
- **status complexo:** `varchar(50) NOT NULL`

## Exemplo Completo

```sql
-- Correta
CREATE TABLE seller_profiles (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid NOT NULL REFERENCES users(id) ON DELETE RESTRICT,
  display_name varchar(255) NOT NULL,
  description text,
  status varchar(50) NOT NULL DEFAULT 'pending_review',
  requested_at timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  reviewed_at timestamp NULL,
  reviewed_by_id uuid REFERENCES users(id) ON DELETE SET NULL,
  rejection_reason text,
  approved_at timestamp NULL,
  suspended_at timestamp NULL,
  created_at timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  
  CONSTRAINT seller_profiles_user_id_unique UNIQUE (user_id),
  CONSTRAINT seller_profiles_status_check CHECK (status IN ('pending_review', 'approved', 'rejected', 'suspended'))
);

CREATE UNIQUE INDEX seller_profiles_user_id_idx ON seller_profiles(user_id);
CREATE INDEX seller_profiles_status_idx ON seller_profiles(status);
CREATE INDEX seller_profiles_requested_at_idx ON seller_profiles(requested_at);
```

Para tabelas ligadas a `users`, evite `ON DELETE CASCADE` quando houver histórico, auditoria ou retenção legal. A estratégia padrão para LGPD é anonimização seletiva, não exclusão física em cascata.

## Rails Migrations e ActiveRecord

Ao gerar migrações Rails, siga:

```bash
rails generate model SellerProfile user:references display_name:string status:string requested_at:datetime
```

Rails criará automaticamente:

```ruby
create_table :seller_profiles do |t|
  t.references :user, type: :uuid, null: false, foreign_key: true
  t.string :display_name, null: false
  t.string :status, default: 'pending_review', null: false
  t.datetime :requested_at, null: false, default: -> { 'CURRENT_TIMESTAMP' }
  
  t.timestamps
end
```

## Verificação de Conformidade

Ao revisar modelos de dados, verifique:

- [ ] Tabelas são plural, snake_case
- [ ] Colunas são singular, snake_case
- [ ] Chaves primárias são `id` uuid
- [ ] Chaves estrangeiras são `{tabela}_id`
- [ ] Timestamps usam `_at` suffix
- [ ] Constraints têm nomes descritivos
- [ ] Índices seguem padrão de nomenclatura
- [ ] Status/enums são lowercase com underscores
- [ ] Sem abreviações em nomes
- [ ] Sem CamelCase exceto em comentários

## Referências

- [PostgreSQL Naming Conventions](https://www.postgresql.org/docs/)
- [Rails Migrations](https://guides.rubyonrails.org/active_record_migrations.html)
- [Database Design Best Practices](https://use-the-index-luke.com/)
