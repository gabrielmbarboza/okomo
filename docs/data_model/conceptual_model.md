# Modelo Conceitual — Identity

## Visão Geral

O contexto de **Identity** é responsável pelo gerenciamento de usuários, autenticação, autorização e perfis de vendedor dentro do Okomo. Este documento descreve as entidades de negócio e seus relacionamentos de forma independente de tecnologia.

## Entidades

### User

Representa uma pessoa que interage com a plataforma Okomo como comprador, vendedor ou administrador.

**Responsabilidades:**
- Armazenar credenciais de autenticação
- Manter estado de confirmação de email
- Rastrear último acesso
- Registrar datas de criação e atualização

**Atributos:**
- `id`: Identificador único
- `name`: Nome completo ou apelido
- `email`: Endereço de email único
- `password_digest`: Hash seguro da senha
- `status`: Estado do usuário (`pending_confirmation`, `active`, `suspended`, `deleted`)
- `email_confirmed_at`: Data/hora da confirmação de email
- `last_login_at`: Data/hora do último acesso
- `created_at`: Data de criação
- `updated_at`: Data da última atualização

**Regras de Negócio:**
- Email deve ser único na plataforma
- Usuário começa em status `pending_confirmation`
- Confirmação de email é obrigatória para ativar conta
- Senha é criptografada irreversivelmente (bcrypt)
- Usuários suspensos podem ter acesso revogado temporariamente

**Relacionamentos:**
- Possui muitos `Roles` através de `UserRole`
- Possui zero ou um `SellerProfile`
- Possui muitos `EmailConfirmationToken`
- Possui muitos `PasswordResetToken`

### Role

Define permissões e responsabilidades dentro do sistema.

**Responsabilidades:**
- Definir um conjunto de permissões
- Ser atribuído a usuários para criar grupos de autorização

**Atributos:**
- `id`: Identificador único
- `name`: Nome da role (ex: `buyer`, `seller`, `platform_admin`)
- `description`: Descrição das responsabilidades
- `created_at`: Data de criação
- `updated_at`: Data da última atualização

**Regras de Negócio:**
- Roles predefinidas no sistema (`buyer`, `seller`, `admin`)
- Nome de role é único
- Cada role descreve um conjunto específico de permissões

**Relacionamentos:**
- Possui muitos `Users` através de `UserRole`

### UserRole

Tabela de junção que associa usuários e roles em um relacionamento muitos-para-muitos.

**Responsabilidades:**
- Registrar atribuição de role a usuário
- Permitir múltiplas roles por usuário
- Rastrear quando a role foi atribuída

**Atributos:**
- `id`: Identificador único
- `user_id`: Referência ao `User`
- `role_id`: Referência ao `Role`
- `created_at`: Data da atribuição

**Regras de Negócio:**
- Cada usuário recebe automaticamente a role `buyer` ao confirmar email
- Cada usuário pode ter múltiplas roles
- Não há dois pares (user_id, role_id) duplicados
- Histórico de atribuições é rastreado por `created_at`

### SellerProfile

Representa o perfil de um usuário como vendedor na plataforma.

**Responsabilidades:**
- Armazenar informações públicas do vendedor
- Gerenciar processo de aprovação de vendedores
- Rastrear status de revisão e suspensões
- Manter histórico de ações administrativas

**Atributos:**
- `id`: Identificador único
- `user_id`: Referência ao `User` (um-para-um)
- `display_name`: Nome público do vendedor
- `description`: Descrição da loja/vendedor
- `status`: Estado do perfil (`pending_review`, `approved`, `rejected`, `suspended`)
- `requested_at`: Data de solicitação para ser vendedor
- `reviewed_at`: Data da revisão
- `reviewed_by_user_id`: Referência ao `User` com role `platform_admin` que revisou
- `rejection_reason`: Motivo da rejeição (se aplicável)
- `approved_at`: Data da aprovação
- `suspended_at`: Data da suspensão (se aplicável)
- `created_at`: Data de criação
- `updated_at`: Data da última atualização

**Regras de Negócio:**
- Um `User` tem no máximo um `SellerProfile`
- Novo perfil começa em status `pending_review`
- Apenas um usuário administrativo pode revisar e aprovar
- Perfis rejeitados ou suspensos não podem vender
- Histórico completo de ações deve ser rastreado

**Relacionamentos:**
- Pertence a um `User`
- Pode ser revisado por um `User` com role `platform_admin`

### EmailConfirmationToken

Token temporário para confirmar a propriedade de um endereço de email.

**Responsabilidades:**
- Validar propriedade de email
- Permitir que apenas proprietários confirmem contas
- Expirar automaticamente após período
- Impedir reutilização de tokens

**Atributos:**
- `id`: Identificador único
- `user_id`: Referência ao `User`
- `token_digest`: Hash do token (por segurança, não armazenar token em texto plano)
- `expires_at`: Data/hora de expiração
- `used_at`: Data/hora de uso (NULL se não utilizado)
- `created_at`: Data de criação

**Regras de Negócio:**
- Token é gerado aleatoriamente e irrevogável
- Token expira após X horas (configurável, ex: 24h)
- Token não pode ser reutilizado após expiração
- Quando utilizado, `used_at` é preenchido
- Múltiplos tokens por usuário são permitidos (para reenvios)

**Relacionamentos:**
- Pertence a um `User`

### PasswordResetToken

Token temporário para redefinir a senha de um usuário.

**Responsabilidades:**
- Validar identidade do usuário para reset de senha
- Permitir que usuários restem próprias senhas
- Expirar automaticamente após período
- Impedir reutilização de tokens

**Atributos:**
- `id`: Identificador único
- `user_id`: Referência ao `User`
- `token_digest`: Hash do token
- `expires_at`: Data/hora de expiração
- `used_at`: Data/hora de uso (NULL se não utilizado)
- `created_at`: Data de criação

**Regras de Negócio:**
- Token é gerado aleatoriamente e irrevogável
- Token expira após X horas (configurável, ex: 2h)
- Token não pode ser reutilizado após expiração ou uso
- Quando utilizado, `used_at` é preenchido
- Múltiplos tokens por usuário são permitidos

**Relacionamentos:**
- Pertence a um `User`

## Relacionamentos

### User ↔ Role (Muitos-para-Muitos)

```
User (1) ──── (N) UserRole ──── (1) Role
```

- Um `User` pode ter múltiplas `Roles`
- Uma `Role` pode ser atribuída a múltiplos `Users`
- A tabela de junção `UserRole` conecta ambos

**Exemplo:**
- Usuário "alice@example.com" tem roles: `buyer`, `seller`
- Usuário "bob@example.com" tem role: `buyer`
- Papel `buyer` é atribuído a muitos usuários

### User ↔ SellerProfile (Um-para-Um)

```
User (1) ─────── (0..1) SellerProfile
```

- Um `User` pode ter no máximo um `SellerProfile`
- Um `SellerProfile` pertence a exatamente um `User`
- Relacionamento é opcional (nem todo usuário é vendedor)

### User ← EmailConfirmationToken (Um-para-Muitos)

```
User (1) ────── (N) EmailConfirmationToken
```

- Um `User` pode ter múltiplos `EmailConfirmationTokens` (para reenvios)
- Cada token pertence a um único `User`

### User ← PasswordResetToken (Um-para-Muitos)

```
User (1) ────── (N) PasswordResetToken
```

- Um `User` pode ter múltiplos `PasswordResetTokens` (para solicitações anteriores)
- Cada token pertence a um único `User`

### SellerProfile ← User (Auto-referência)

```
User (`platform_admin`) ──── (N) SellerProfile (reviewed_by_user_id)
```

- Um `User` com papel administrativo pode revisar múltiplos `SellerProfiles`
- Cada `SellerProfile` revisado referencia o usuário que o revisou

## Fluxos de Negócio

### Registro de Novo Usuário

1. Usuário se registra com email e senha
2. `User` é criado com status `pending_confirmation`
3. `EmailConfirmationToken` é gerado e enviado por email
4. Usuário clica no link do email com o token
5. Token é validado e `email_confirmed_at` é preenchido
6. `User.status` é alterado para `active`
7. `UserRole` é criado com role `buyer`
8. Usuário pode fazer login

### Conversão para Vendedor

1. Usuário autenticado com role `buyer` solicita ser vendedor
2. `SellerProfile` é criado com status `pending_review`
3. Admin/Moderador revisa o perfil
4. Se aprovado:
   - `SellerProfile.status` = `approved`
   - `SellerProfile.approved_at` = agora
   - `UserRole` é criado com role `seller`
5. Se rejeitado:
   - `SellerProfile.status` = `rejected`
   - `SellerProfile.rejection_reason` é preenchido
   - Usuário permanece apenas como `buyer`

### Reset de Senha

1. Usuário solicita reset de senha
2. Sistema valida email e cria `PasswordResetToken`
3. Token é enviado por email
4. Usuário clica no link com token
5. Usuário entra nova senha
6. Token é validado, `PasswordResetToken.used_at` é preenchido
7. `User.password_digest` é atualizado
8. Token não pode ser reutilizado

## Regras de Segurança

- Senhas são hashed com bcrypt (mínimo 10 rounds)
- Tokens não são armazenados em texto plano (apenas digest)
- Tokens expiram automaticamente
- Reutilização de tokens é bloqueada
- Email é validado antes de confirmar
- Apenas admins podem revisar perfis de vendedor
- Histórico de ações administrativas é rastreado

## Restrições e Integridade

- `users.email` é UNIQUE
- `roles.name` é UNIQUE
- `user_roles(user_id, role_id)` é UNIQUE
- `seller_profiles.user_id` é UNIQUE
- `email_confirmation_tokens.token_digest` é UNIQUE
- `password_reset_tokens.token_digest` é UNIQUE
- Não há orphans de tokens quando usuários são deletados (DELETE CASCADE)
