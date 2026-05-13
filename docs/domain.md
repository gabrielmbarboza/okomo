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

## Entidades

### User
Conta principal autenticável da plataforma.

Atributos:
* id (UUID)
* email (string, único)
* password_digest (string)
* email_confirmed (boolean)
* created_at (datetime)
* updated_at (datetime)

### Role
Permissão atribuída ao usuário.

Atributos:
* id (UUID)
* name (string: buyer, seller, admin)
* user_id (UUID, FK)

### SellerProfile
Perfil contendo dados cadastrais e status de moderação do vendedor.

Atributos:
* id (UUID)
* seller_id (UUID, FK)
* tax_info (jsonb)
* commercial_info (jsonb)
* status (enum: pending, approved, rejected, suspended)
* moderation_notes (text)
* created_at (datetime)
* updated_at (datetime)

## Casos de Uso

### RegisterUser
Criação de nova conta de usuário.

Fluxo:
1. Valida e-mail e senha
2. Cria User com password hash
3. Gera token de confirmação de e-mail
4. Envia e-mail de confirmação
5. Publica evento UserRegistered

### ConfirmEmail
Confirmação do endereço de e-mail do usuário.

Fluxo:
1. Valida token de confirmação
2. Marca e-mail como confirmado
3. Atribui role buyer automaticamente
4. Publica evento UserEmailConfirmed

### AuthenticateUser
Autenticação do usuário na plataforma.

Fluxo:
1. Valida credenciais (email + password)
2. Gera JWT token
3. Retorna token e dados do usuário
4. Publica evento UserAuthenticated

### RequestPasswordRecovery
Solicitação de recuperação de senha.

Fluxo:
1. Valida existência do e-mail
2. Gera token de recuperação
3. Envia e-mail com link seguro
4. Publica evento PasswordRecoveryRequested

### ResetPassword
Redefinição de senha via token.

Fluxo:
1. Valida token de recuperação
2. Atualiza password
3. Invalida token
4. Publica evento PasswordResetCompleted

### RequestSellerRegistration
Solicitação para se tornar vendedor.

Fluxo:
1. Valida dados fiscais e comerciais
2. Cria SellerProfile com status pending
3. Publica evento SellerRegistrationRequested

### ApproveSeller
Aprovação de vendedor por administrador.

Fluxo:
1. Valida permissões de administrador
2. Atualiza status para approved
3. Atribui role seller ao usuário
4. Publica evento SellerApproved

### RejectSeller
Rejeição de vendedor por administrador.

Fluxo:
1. Valida permissões de administrador
2. Atualiza status para rejected
3. Registra motivo da rejeição
4. Publica evento SellerRejected

### SuspendSeller
Suspensão de vendedor por administrador.

Fluxo:
1. Valida permissões de administrador
2. Atualiza status para suspended
3. Registra motivo da suspensão
4. Publica evento SellerSuspended

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

### SellerRegistrationRequested
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