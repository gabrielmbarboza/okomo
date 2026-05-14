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
| status | varchar(50) | NOT NULL | 'pending_confirmation' | Enum: pending_confirmation, active, suspended, deleted |
| email_confirmed_at | timestamp | NULL | | NULL até confirmação |
| last_login_at | timestamp | NULL | | Rastreia último acesso |
| created_at | timestamp | NOT NULL | CURRENT_TIMESTAMP | Data de criação |
| updated_at | timestamp | NOT NULL | CURRENT_TIMESTAMP | Data da última atualização |

**Constraints:**
- PRIMARY KEY: `id`
- UNIQUE: `email`
- CHECK: `status IN ('pending_confirmation', 'active', 'suspended', 'deleted')`
- CHECK: `LENGTH(email) <= 254 AND email LIKE '%@%.%'`

**Índices:**
- PRIMARY: `users_pkey` (id)
- UNIQUE: `users_email_idx` (email)
- REGULAR: `users_status_idx` (status)
- REGULAR: `users_created_at_idx` (created_at)

**Triggers:**
- Atualiza `updated_at` automaticamente em UPDATE

---

### roles

**Propósito:** Armazenar papéis/permissões disponíveis no sistema.

| Coluna | Tipo | Null | Padrão | Comentários |
|--------|------|------|--------|------------|
| id | uuid | NOT NULL | gen_random_uuid() | Chave primária |
| name | varchar(50) | NOT NULL | | Nome único: buyer, seller, admin, moderator |
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
admin      | Acesso administrativo completo
moderator  | Pode revisar perfis e conteúdo
```

---

### user_roles

**Propósito:** Relacionamento muitos-para-muitos entre usuários e roles.

| Coluna | Tipo | Null | Padrão | Comentários |
|--------|------|------|--------|------------|
| id | uuid | NOT NULL | gen_random_uuid() | Chave primária |
| user_id | uuid | NOT NULL | | FK → users(id) |
| role_id | uuid | NOT NULL | | FK → roles(id) |
| created_at | timestamp | NOT NULL | CURRENT_TIMESTAMP | Data da atribuição |

**Constraints:**
- PRIMARY KEY: `id`
- FOREIGN KEY: `user_id` REFERENCES `users(id)` ON DELETE CASCADE
- FOREIGN KEY: `role_id` REFERENCES `roles(id)` ON DELETE RESTRICT
- UNIQUE: `(user_id, role_id)` - Nenhuma duplicação de (user, role)
- CHECK: `user_id IS NOT NULL AND role_id IS NOT NULL`

**Índices:**
- PRIMARY: `user_roles_pkey` (id)
- UNIQUE: `user_roles_user_id_role_id_idx` (user_id, role_id)
- REGULAR: `user_roles_user_id_idx` (user_id)
- REGULAR: `user_roles_role_id_idx` (role_id)

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
| reviewed_by_id | uuid | NULL | | FK → users(id) admin/moderador |
| rejection_reason | text | NULL | | Motivo se rejeitado |
| approved_at | timestamp | NULL | | Data da aprovação |
| suspended_at | timestamp | NULL | | Data da suspensão |
| created_at | timestamp | NOT NULL | CURRENT_TIMESTAMP | Data de criação |
| updated_at | timestamp | NOT NULL | CURRENT_TIMESTAMP | Data da última atualização |

**Constraints:**
- PRIMARY KEY: `id`
- FOREIGN KEY: `user_id` REFERENCES `users(id)` ON DELETE CASCADE
- FOREIGN KEY: `reviewed_by_id` REFERENCES `users(id)` ON DELETE SET NULL
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
- REGULAR: `seller_profiles_reviewed_by_id_idx` (reviewed_by_id)

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
               ├──── (1) ←─── (N) seller_profiles (reviewed_by_id)
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
- `user_roles` referencia `users` - Deletar user deleta roles
- `email_confirmation_tokens` referencia `users` - Deletar user deleta tokens
- `password_reset_tokens` referencia `users` - Deletar user deleta tokens
- `seller_profiles` referencia `users` - Deletar user deleta profile

### DELETE RESTRICT

Aplicado quando:
- `user_roles` referencia `roles` - Não pode deletar role com usuários

### DELETE SET NULL

Aplicado quando:
- `seller_profiles.reviewed_by_id` referencia `users` - Admin deletado não anula histórico

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
