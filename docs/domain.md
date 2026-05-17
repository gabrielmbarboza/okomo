# Modelo de Domínio — Okomo

> Este documento apresenta a visão conceitual do domínio do Okomo, descrevendo os principais Bounded Contexts, entidades, agregados e relacionamentos de negócio.

---

# 1. Visão Geral do Domínio

O Okomo é uma plataforma SaaS de e-commerce voltada para pequenos artesãos e empreendedores, permitindo que Sellers criem suas próprias lojas virtuais e gerenciem:

- catálogo de produtos;
- estoque;
- carrinho e checkout;
- pedidos;
- promoções e cupons;
- pagamentos;
- frete e entregas.

A arquitetura do domínio segue os princípios de Domain-Driven Design (DDD) e está organizada em Bounded Contexts.

---

# 2. Bounded Contexts

| Bounded Context | Responsabilidade |
|----------------|----------------|
| Catalog | Gerenciamento de Product e Variant |
| Inventory | Controle de estoque e reservas |
| Cart | Intenção de compra do Buyer |
| Checkout | Orquestração da finalização da compra |
| Orders | Gestão de pedidos e snapshots financeiros |
| Promotions | Promoções, descontos e cupons |
| Payments | Processamento e conciliação de pagamentos |
| Shipping | Cálculo de frete e entregas |
| Store | Gestão da loja (`Seller`) |
| Identity | Usuários, autenticação e autorização |

---

# 3. Modelo Conceitual de Alto Nível

```text
User (Identity Context)
   ├── has_one Seller (optional)
   └── has_one Buyer (optional)

Seller
   └── owns Store
           └── owns Product
                   └── has_many Variant
                           └── has_one Inventory

Buyer
   └── has_one Cart
           └── contains CartItem

Buyer
   └── starts Checkout
           ├── reserves Inventory
           ├── applies Promotions
           ├── creates Payment
           └── confirms Order

Order
   ├── has_many OrderItem
   ├── has_many Payments
   └── has_one Shipment

Promotion
   ├── has_one Coupon (optional)
   ├── has_many PromotionRule
   └── generates Discount

---

# 4. Bounded Context: Identity

## Responsabilidade

Gerenciamento de usuários, autenticação, autorização e papéis de negócio.

## Agregados

### User (Aggregate Root)

`User` é a entidade raiz que representa uma conta de acesso à plataforma.

**Atributos:**

* `id` (UUID) - Identificador único
* `email` (string, único) - Endereço de e-mail do usuário
* `password_digest` (string) - Hash da senha utilizando bcrypt
* `status` (enum: pending_confirmation, active, blocked, deactivated) - Estado da conta
* `email_confirmed_at` (datetime, nullable) - Data de confirmação do e-mail
* `created_at` (datetime) - Data de criação
* `updated_at` (datetime) - Última atualização

**Relacionamentos:**

* `has_many :user_roles` - Atribuições de roles (Auditável)
* `has_one :seller_profile` (opcional) - Perfil de vendedor se aplicável

**Invariantes:**

* Todo User com `email_confirmed_at` preenchido recebe automaticamente o role `buyer`
* O role `buyer` não pode ser revogado após atribuição
* Um User bloqueado não pode fazer login ou realizar ações

---

### Role (Entity / Catálogo Global)

`Role` representa o catálogo global e explícito de papéis da plataforma.
Embora tenha comportamento simples nesta fase, é modelado como entidade do
Identity domain para manter identidade própria, nomenclatura estável e
consistência com `UserRole`.

**Atributos:**

* `id` (UUID) - Identificador único
* `name` (enum: buyer, seller, platform_admin) - Nome do role
* `description` (string) - Descrição do role
* `created_at` (datetime) - Data de criação
* `updated_at` (datetime) - Última atualização

**Características:**

* Não muda frequentemente
* Gerenciado apenas por administradores do sistema
* Cada role tem um conjunto específico de permissões
* Roles válidos no MVP: `buyer`, `seller`, `platform_admin`

---

### UserRole (Entity)

`UserRole` representa a atribuição auditável de um `Role` a um `User` em um ponto específico no tempo.
Ele não é apenas uma tabela de junção: preserva o histórico completo de
concessão e revogação de papéis.

**Atributos:**

* `id` (UUID) - Identificador único
* `user_id` (UUID, FK) - Referência ao User
* `role_id` (UUID, FK) - Referência ao Role
* `granted_at` (datetime) - Data de concessão do role
* `revoked_at` (datetime, nullable) - Data de revogação (null = ativo)
* `granted_by_user_id` (UUID, FK, nullable) - Qual usuário concedeu o role
* `revoked_by_user_id` (UUID, FK, nullable) - Qual usuário revogou o role
* `reason` (string, nullable) - Motivo da concessão/revogação
* `created_at` (datetime)
* `updated_at` (datetime)

**Características:**

* Fornece trilha de auditoria completa
* Preserva histórico de todas as concessões e revogações
* `revoked_at` é NULL enquanto o role está ativo para o usuário
* O role `buyer` nunca pode ser revogado (revoked_at permanece NULL)
* Roles adicionais, como `seller` e `platform_admin`, podem ser concedidos e revogados ao longo do tempo

**Relacionamentos:**

* `belongs_to :user`
* `belongs_to :role`
* `belongs_to :granted_by_user` (User, optional)
* `belongs_to :revoked_by_user` (User, optional)

---

### SellerProfile (Entity)

`SellerProfile` representa o perfil de um vendedor, incluindo dados comerciais e status de moderação.

**Atributos:**

* `id` (UUID) - Identificador único
* `user_id` (UUID, FK, único) - Referência ao User (um-para-um)
* `display_name` (string) - Nome da loja exibido publicamente
* `description` (text, nullable) - Descrição da loja
* `status` (enum: pending_review, approved, rejected, suspended) - Estado da aplicação
* `document_type` (enum: cpf, cnpj, mei) - Tipo de documento fiscal
* `document_number` (string) - Número do documento (criptografado em repouso)
* `legal_name` (string) - Razão social ou nome legal
* `contact_email` (string) - E-mail de contato comercial
* `contact_phone` (string) - Telefone de contato
* `commercial_address` (jsonb) - Endereço comercial (rua, número, cidade, estado, CEP)
* `requested_at` (datetime) - Data da solicitação
* `reviewed_at` (datetime, nullable) - Data da análise
* `reviewed_by_user_id` (UUID, FK, nullable) - Qual administrador revisou
* `approved_at` (datetime, nullable) - Data de aprovação
* `rejected_at` (datetime, nullable) - Data de rejeição
* `rejection_reason` (text, nullable) - Motivo da rejeição
* `suspended_at` (datetime, nullable) - Data de suspensão
* `suspension_reason` (text, nullable) - Motivo da suspensão
* `created_at` (datetime)
* `updated_at` (datetime)

**Relacionamentos:**

* `belongs_to :user`
* `belongs_to :reviewed_by_user` (User, optional)

**Estados:**

1. **pending_review** - Inicial, aguardando análise
2. **approved** - Aprovado, pode vender
3. **rejected** - Rejeitado, não pode vender
4. **suspended** - Suspenso temporariamente

**Transições Válidas:**

```
pending_review → approved (sucesso)
pending_review → rejected (rejeição)
approved → suspended (violação)
suspended → approved (resolução)
```

---

## Casos de Uso

### Register User

Criação de nova conta de usuário na plataforma.

**Fluxo:**

1. Valida e-mail (formato e unicidade)
2. Valida força da senha
3. Cria User com `status = pending_confirmation` e `password_digest`
4. Gera token seguro de confirmação de e-mail
5. Envia e-mail de confirmação
6. Publica evento `UserRegistered`

**Pós-condições:**

* User criado mas não pode fazer compras
* E-mail de confirmação enviado

---

### Confirm Email

Confirmação do endereço de e-mail do usuário.

**Fluxo:**

1. Valida token de confirmação (expiração, existência)
2. Marca `email_confirmed_at` com timestamp
3. Altera `status` para `active`
4. Cria automaticamente `UserRole` com `buyer` role
5. Publica evento `UserEmailConfirmed`

**Pós-condições:**

* User pode fazer login
* User recebeu role `buyer`
* UserRole criado e auditável

**Regra Fundamental:**

* `buyer` é o papel base de todo User confirmado e não pode ser revogado

---

### Authenticate User

Autenticação do usuário na plataforma via credenciais.

**Fluxo:**

1. Valida credenciais (email + password)
2. Valida que User não está bloqueado
3. Valida que User confirmou e-mail
4. Gera JWT token com informações do usuário
5. Retorna token e informações básicas
6. Publica evento `UserAuthenticated`

---

### Request Password Recovery

Solicitação de recuperação de senha.

**Fluxo:**

1. Valida existência do e-mail
2. Gera token seguro de recuperação (expiração: 1 hora)
3. Envia e-mail com link seguro
4. Publica evento `PasswordRecoveryRequested`

---

### Reset Password

Redefinição de senha via token.

**Fluxo:**

1. Valida token de recuperação
2. Atualiza `password_digest`
3. Invalida token (não reutilizável)
4. Publica evento `PasswordResetCompleted`

---

### Request Seller Application

Solicitação para se tornar vendedor.

**Fluxo:**

1. Valida que User não é bloqueado ou deativado
2. Valida dados fiscais (documento, formato)
3. Valida dados comerciais (nome da loja, contatos)
4. Cria `SellerProfile` com `status = pending_review`
5. Define `requested_at` com timestamp
6. Publica evento `SellerApplicationSubmitted`

**Pós-condições:**

* SellerProfile criado aguardando revisão
* User ainda não possui role `seller`

---

### Role Lifecycle

Papéis são concedidos e revogados por meio de `UserRole`.

**Fluxo:**

1. Um role global existente em `Role` é selecionado.
2. Um novo `UserRole` é criado com `granted_at`, `granted_by_user_id` e `reason`.
3. Enquanto `revoked_at` for `NULL`, o role está ativo.
4. Para revogar, o mesmo `UserRole` recebe `revoked_at`, `revoked_by_user_id` e motivo.
5. Uma nova concessão futura cria outro `UserRole`, preservando o histórico anterior.

**Invariantes:**

* `buyer` é atribuído automaticamente após confirmação de e-mail.
* `buyer` não pode ser revogado.
* `seller` depende do fluxo de aprovação de `SellerProfile`.
* `platform_admin` só pode ser concedido por operação administrativa explícita.

---

### Seller Approval Flow

O fluxo de vendedor é separado do ciclo de papéis para manter responsabilidades claras.

**Fluxo:**

1. User confirmado submete um `SellerProfile` com `status = pending_review`.
2. Administrador com role `platform_admin` revisa a aplicação.
3. Em caso de aprovação, `SellerProfile` muda para `approved` e o role `seller` é concedido.
4. Em caso de rejeição, `SellerProfile` muda para `rejected` e nenhum role `seller` é concedido.
5. Em caso de suspensão posterior, `SellerProfile` muda para `suspended` e o role `seller` é revogado de forma auditável.

---

### Approve Seller

Aprovação de vendedor por administrador.

**Fluxo:**

1. Valida que revisor possui role `platform_admin`
2. Valida que SellerProfile está em `pending_review`
3. Altera `status` para `approved`
4. Define `approved_at` e `reviewed_by_user_id`
5. Cria `UserRole` com `seller` role
6. Publica evento `SellerApproved`

**Pós-condições:**

* User recebeu role `seller`
* SellerProfile está aprovado
* Pode criar produtos

---

### Reject Seller

Rejeição de vendedor por administrador.

**Fluxo:**

1. Valida que revisor possui role `platform_admin`
2. Valida que SellerProfile está em `pending_review`
3. Altera `status` para `rejected`
4. Define `rejected_at`, `reviewed_by_user_id` e `rejection_reason`
5. Publica evento `SellerRejected`

**Pós-condições:**

* SellerProfile rejeitado
* User não recebe role `seller`

---

### Suspend Seller

Suspensão de vendedor por administrador.

**Fluxo:**

1. Valida que revisor possui role `platform_admin`
2. Valida que SellerProfile está em `approved`
3. Altera `status` para `suspended`
4. Define `suspended_at` e `suspension_reason`
5. Revoga `seller` role (cria UserRole com `revoked_at`)
6. Publica evento `SellerSuspended`

**Pós-condições:**

* SellerProfile suspenso
* User perde role `seller` (auditável)
* Não pode mais vender

---

### Reactivate Seller

Reativação de um seller suspenso por administrador.

**Fluxo:**

1. Valida que revisor possui role `platform_admin`
2. Valida que SellerProfile está em `suspended`
3. Altera `status` de volta para `approved`
4. Limpa `suspended_at` e `suspension_reason`
5. Restaura `seller` role (novo UserRole com granted_at)
6. Publica evento `SellerReactivated`

**Pós-condições:**

* SellerProfile novamente aprovado
* User recupera role `seller`
* Pode vender novamente

---

## Domain Events

### UserRegistered
Novo usuário criado no sistema.

Payload:
* user_id (UUID)
* email (string)
* occurred_at (datetime)

Consumidores típicos:
* SendConfirmationEmailJob

### UserEmailConfirmed
E-mail do usuário confirmado com sucesso.

Payload:
* user_id (UUID)
* email (string)
* occurred_at (datetime)

Consumidores típicos:
* Audit Logging

### UserAuthenticated
Usuário autenticado com sucesso.

Payload:
* user_id (UUID)
* email (string)
* occurred_at (datetime)

Consumidores típicos:
* Audit Logging

### PasswordRecoveryRequested
Usuário solicitou recuperação de senha.

Payload:
* user_id (UUID)
* email (string)
* recovery_token (string)
* occurred_at (datetime)

Consumidores típicos:
* SendPasswordRecoveryEmailJob

### PasswordResetCompleted
Senha redefinida com sucesso.

Payload:
* user_id (UUID)
* email (string)
* occurred_at (datetime)

Consumidores típicos:
* Audit Logging

### SellerApplicationSubmitted
Solicitação para se tornar vendedor.

Payload:
* user_id (UUID)
* seller_profile_id (UUID)
* occurred_at (datetime)

Consumidores típicos:
* NotifyAdminJob

### SellerApproved
Vendedor aprovado para vender na plataforma.

Payload:
* user_id (UUID)
* seller_profile_id (UUID)
* occurred_at (datetime)

Consumidores típicos:
* NotifySellerApprovalJob
* Audit Logging

### SellerRejected
Vendedor rejeitado na solicitação.

Payload:
* user_id (UUID)
* seller_profile_id (UUID)
* reason (string)
* occurred_at (datetime)

Consumidores típicos:
* NotifySellerRejectionJob
* Audit Logging

### SellerSuspended
Vendedor suspenso temporariamente.

Payload:
* user_id (UUID)
* seller_profile_id (UUID)
* reason (string)
* occurred_at (datetime)

Consumidores típicos:
* NotifySellerSuspensionJob
* Audit Logging

## Regras de Negócio

1. Todo User com e-mail confirmado recebe automaticamente o role buyer.
2. Seller é um role adicional que exige solicitação e aprovação.
3. Um mesmo User pode possuir múltiplos roles simultaneamente.
4. E-mail deve ser único em todo o sistema.
5. Senha deve ter no mínimo 8 caracteres.
6. Tokens de recuperação de senha expiram em 1 hora.
7. Tokens de confirmação de e-mail expiram em 24 horas.
8. SellerProfile passa por moderação manual antes da aprovação.
