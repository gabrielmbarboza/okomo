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