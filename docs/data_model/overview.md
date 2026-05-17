# Visão Global do Modelo de Dados

## Propósito

Este documento apresenta uma visão consolidada e arquitetônica do modelo de dados do Okomo, fornecendo compreensão clara dos relacionamentos entre os diferentes Bounded Contexts.

A visão global serve para:

- **Comunicação arquitetônica**: Discutir integração entre domínios em reuniões de design
- **Onboarding**: Fornecer contexto rápido do modelo ao integrar novos desenvolvedores
- **Planejamento de features**: Identificar impactos em cascata entre contextos
- **Revisão de arquitetura**: Validar decisões de design antes da implementação
- **Evolução incremental**: Manter registro de como o modelo evolui ao longo do tempo

## Visão Geral

O Okomo é organizado em **8 Bounded Contexts** principais, cada um responsável por um domínio específico:

```
┌─────────────────────────────────────────────────────────────┐
│ OKOMO - Plataforma de E-commerce para Artesãos              │
└─────────────────────────────────────────────────────────────┘

┌──────────────┐   ┌──────────────┐   ┌──────────────┐
│   IDENTITY   │   │   CATALOG    │   │  INVENTORY   │
│              │   │              │   │              │
│ User, Role   │──▶│ Product      │──▶│ Inventory    │
│ Seller       │   │ Variant      │   │ Reservation  │
│ Buyer        │   └──────────────┘   └──────────────┘
└──────────────┘

        ▼
┌──────────────┐   ┌──────────────┐   ┌──────────────┐
│    ORDERS    │   │   CHECKOUT   │   │  PAYMENTS    │
│              │   │              │   │              │
│ Order        │──▶│ Session      │   │ Payment      │
│ OrderItem    │   └──────────────┘   └──────────────┘
└──────────────┘

        ▼
┌──────────────┐   ┌──────────────┐
│   SHIPPING   │   │ PROMOTIONS   │
│              │   │              │
│ Shipment     │   │ Coupon       │
└──────────────┘   │ Redemption   │
                   └──────────────┘
```

## Bounded Contexts e Entidades

### 1. Identity (Identidade e Autorização)

**Responsabilidade:** Gestão de usuários, autenticação, autorização e papéis de negócio.

**Principais Entidades:**

- **User**: Conta de acesso à plataforma. Representada como um usuário autenticável com e-mail e senha.
  - Atributos: id (UUID), name, email, password_digest, status, email_confirmed_at, terms_accepted_at, privacy_policy_accepted_at, consent_version, blocked_at, deactivated_at, anonymized_at, deleted_at, created_at, updated_at
  - Estratégia LGPD: anonimização seletiva em vez de exclusão física como padrão.

- **Role**: Catálogo global de papéis da plataforma (`buyer`, `seller`, `platform_admin`).
  - Atributos: id (UUID), name, description, created_at, updated_at

- **UserRole**: Entidade auditável que representa a atribuição de um Role a um User.
  - Atributos: id (UUID), user_id, role_id, granted_at, revoked_at, granted_by_user_id, revoked_by_user_id, reason, created_at, updated_at
  - Preserva histórico completo de concessões e revogações.

- **SellerProfile**: Perfil de vendedor com informações comerciais e status de aprovação.
  - Atributos: id (UUID), user_id (um-para-um com User), display_name, status, requested_at, reviewed_by_user_id, approved_at, rejected_at, suspended_at
  - Estados: pending_review, approved, rejected, suspended

**Relacionamentos Importantes:**
- Um User pode ter múltiplos Roles (através de UserRole)
- Um User pode ter um SellerProfile (relacionamento um-para-um opcional)
- Um SellerProfile é revisado por um User com role `platform_admin`
- Todo User confirmado recebe role `buyer`
- O role `buyer` não pode ser revogado
- Orders, Payments, CouponRedemptions e auditoria podem reter referência técnica a `user_id` após anonimização.
- Dados pessoais diretos de User e SellerProfile devem ser removidos, substituídos ou criptografados conforme política de retenção.

**Diagrama DBML específico:** `docs/data_model/dbdiagram/identity.dbml`

---

### 2. Catalog (Catálogo de Produtos)

**Responsabilidade:** Gestão de produtos, variantes e metadados comerciais.

**Principais Entidades:**

- **Product**: Representa um produto conceitual criado por um Seller.
  - Atributos: id (UUID), seller_profile_id, name, description, status, created_at, updated_at
  - Estados: draft, published, archived

- **Variant**: Representa uma variante específica de um produto com preço e atributos únicos.
  - Atributos: id (UUID), product_id, name, sku, price, status, created_at, updated_at
  - Estados: draft, published, archived
  - Cada variante possui um único SKU (Stock Keeping Unit)

**Relacionamentos Importantes:**
- Um SellerProfile possui múltiplos Products (através de seller_profile_id)
- Um Product possui múltiplas Variants (um-para-muitos)
- Uma Variant referencia exatamente um Product

**Decisão Arquitetônica:** Segundo ADR-007, a Variant é responsável por pricing e inventory. Isso significa que preços e controle de estoque são mantidos no nível de Variant, não de Product.

---

### 3. Inventory (Controle de Estoque)

**Responsabilidade:** Gestão de disponibilidade de estoque, reservas e expiração de reservas.

**Principais Entidades:**

- **Inventory**: Controla a quantidade disponível e reservada para uma Variant.
  - Atributos: id (UUID), variant_id (um-para-um), quantity, reserved_quantity, updated_at
  - A quantidade é sempre: `available = quantity - reserved_quantity`

- **InventoryReservation**: Representa uma reserva de estoque com expiração.
  - Atributos: id (UUID), inventory_id, order_item_id, quantity, status, expires_at, released_at, created_at, updated_at
  - Estados: pending, confirmed, released, expired
  - Cada reserva tem prazo de expiração automática (ex: 10 minutos)

**Relacionamentos Importantes:**
- Uma Variant possui exatamente uma Inventory (um-para-um)
- Uma Inventory pode ter múltiplas InventoryReservations (um-para-muitos)
- Uma InventoryReservation referencia um OrderItem (quando confirmada)

**Decisões Arquitetônicas:**
- Segundo ADR-004, é aplicado Pessimistic Locking para garantir consistência
- Segundo ADR-009, jobs de expiração de reservas são idempotentes
- Reservas expiram automaticamente se não forem confirmadas no prazo

---

### 4. Orders (Gestão de Pedidos)

**Responsabilidade:** Gestão de pedidos, histórico e snapshots de preços.

**Principais Entidades:**

- **Order**: Representa um pedido realizado por um Buyer.
  - Atributos: id (UUID), user_id, status, total_amount, discount_amount, coupon_id (opcional), created_at, updated_at
  - Estados: pending, confirmed, shipped, delivered, cancelled
  - Armazena snapshot de preços total (com e sem desconto)

- **OrderItem**: Representa um item dentro de um pedido.
  - Atributos: id (UUID), order_id, variant_id, quantity, unit_price (snapshot), line_total, created_at
  - O unit_price é um snapshot do preço no momento da compra (não pode mudar retroativamente)

**Relacionamentos Importantes:**
- Um User (Buyer) pode ter múltiplos Orders
- Um Order possui múltiplos OrderItems (um-para-muitos)
- Um OrderItem referencia uma Variant (preserva histórico de produto/preço)
- Um Order pode ter um Coupon aplicado (referência opcional)

**Decisão Arquitetônica:** Segundo ADR-005, OrderItem mantém snapshot de preço (unit_price). Isso garante que o histórico de um pedido não seja afetado por mudanças de preço no Catalog.

---

### 5. Checkout (Orquestração de Checkout)

**Responsabilidade:** Orquestração do processo de finalização de compra.

**Principais Entidades:**

- **CheckoutSession**: Representa uma sessão de checkout para um Order.
  - Atributos: id (UUID), order_id (um-para-um), status, created_at, updated_at
  - Estados: pending, in_progress, completed, abandoned
  - Coordena: validação de estoque, aplicação de descontos, processamento de pagamento

**Relacionamentos Importantes:**
- Uma CheckoutSession referencia exatamente um Order (um-para-um)
- Uma CheckoutSession coordena a reserva de Inventory

**Decisão Arquitetônica:** Segundo ADR-006, o checkout inicia a reserva de inventory. Quando um CheckoutSession é criado, as reservas são imediatamente confirmadas.

---

### 6. Payments (Processamento de Pagamentos)

**Responsabilidade:** Processamento e conciliação de pagamentos.

**Principais Entidades:**

- **Payment**: Representa uma tentativa ou processamento de pagamento.
  - Atributos: id (UUID), order_id, amount, status, payment_method, gateway_transaction_id, created_at, updated_at
  - Estados: pending, processing, approved, declined, refunded
  - Integra com gateways de pagamento (ex: Stripe, PagSeguro)

**Relacionamentos Importantes:**
- Um Order pode ter múltiplos Payments (suporta múltiplas tentativas ou pagamentos parciais)
- Um Payment armazena referência ao gateway de pagamento (gateway_transaction_id)

---

### 7. Shipping (Cálculo e Gestão de Frete)

**Responsabilidade:** Cálculo de frete, rastreamento e gestão de entregas.

**Principais Entidades:**

- **Shipment**: Representa a entrega de um Order.
  - Atributos: id (UUID), order_id (um-para-um), tracking_number, status, shipping_method, estimated_delivery_at, delivered_at, created_at, updated_at
  - Estados: pending, processing, shipped, in_transit, delivered, failed
  - Armazena número de rastreamento e estimativa de entrega

**Relacionamentos Importantes:**
- Um Order pode ter uma Shipment (um-para-um, opcional)
- Uma Shipment referencia um Order

---

### 8. Promotions (Promoções e Cupons)

**Responsabilidade:** Gestão de cupons de desconto e promoções.

**Principais Entidades:**

- **Coupon**: Representa um cupom de desconto criado por um Seller.
  - Atributos: id (UUID), created_by_id, code, discount_value, discount_type, status, valid_from, valid_until, max_uses, current_uses, created_at, updated_at
  - Estados: active, inactive, expired
  - Tipos de desconto: percentage (ex: 10%), fixed (ex: R$ 5)
  - Suporta limite de usos (max_uses)

- **CouponRedemption**: Representa o uso de um Coupon em um Order.
  - Atributos: id (UUID), coupon_id, user_id, order_id, redeemed_at, created_at
  - Cada redenção é imutável e rastreada para auditoria

**Relacionamentos Importantes:**
- Um User (Seller) cria múltiplos Coupons
- Um Coupon pode ter múltiplas CouponRedemptions
- Uma CouponRedemption referencia Coupon, User (Buyer) e Order
- Um Order pode aplicar opcionalmente um Coupon

**Decisão Arquitetônica:** Segundo ADR-008, Promotions é um Bounded Context separado e Coupon é uma entidade principal.

---

## Fluxos de Dados Principais

### Fluxo de Criação de Produto

```
Seller (User + SellerProfile)
  ├─ cria Product
  ├─ cria Variant (com price, sku)
  └─ cria Inventory (linked a Variant)
```

### Fluxo de Compra

```
Buyer (User)
  ├─ seleciona Variants do Catalog
  ├─ inicia CheckoutSession
  │  ├─ reserva Inventory (InventoryReservation com expiration)
  │  ├─ aplica opcional Coupon
  │  └─ calcula Order total
  ├─ realiza Payment (pode ser múltiplo)
  ├─ Order é confirmado
  ├─ InventoryReservation é confirmada
  ├─ Shipment é criado
  └─ CouponRedemption registrada (se coupon usado)
```

---

## Padrões de Modelagem

### UUIDs como Chaves Primárias

Todas as tabelas usam UUID v4 como chave primária. Decisão documentada em ADR-003.

**Benefícios:**
- Distribuição: Podem ser gerados no cliente ou servidor
- Privacidade: Não expõem sequência de IDs
- Sharding: Facilita particionamento horizontal

### Timestamps Implícitos

Entidades críticas incluem `created_at` e `updated_at` para auditoria.

### Status como Strings (Enum)

Estados são armazenados como varchar com valores pré-definidos (não enum PG). Isso oferece:
- Flexibilidade para evoluir estados sem migration
- Compatibilidade com ORMs
- Clareza em queries SQL

### Soft Deletes e Anonimização

Soft delete (`deleted_at`) pode existir como ferramenta técnica, mas não é a estratégia de privacidade principal. Para LGPD, o modelo deve suportar anonimização seletiva:

- preservar IDs técnicos quando necessários para retenção fiscal, antifraude, auditoria, Orders e Payments;
- remover ou substituir dados pessoais diretos quando a retenção legal permitir;
- marcar `anonymized_at` em `users`;
- impedir login e uso operacional da conta anonimizada;
- evitar `DELETE CASCADE` de `users` para registros históricos obrigatórios.

### Snapshots de Preço

OrderItem mantém `unit_price` imutável para preservar histórico de compra.

---

## Evoluindo o Modelo

Este modelo é um **artefato vivo** que evoluirá conforme a implementação progride:

### Princípios de Evolução

1. **Bounded Context First**: Mudanças são feitas dentro de seus contextos específicos
2. **Backward Compatible**: Novas colunas são adicionadas sem quebrar queries existentes
3. **Documented**: Cada mudança maior é registrada em um ADR ou arquivo de changelog
4. **Incremental**: Migrações Rails implementam mudanças passo a passo

### Extensões Planejadas

- **Store Context**: Possível novo contexto para gestão de loja (branding, configurações de frete)
- **Reviews & Ratings**: Context para avaliações de produtos
- **Notifications**: Context para alertas e comunicações
- **Payments Extended**: Suporte a mais gateways de pagamento
- **Analytics**: Event logging para análise de comportamento

---

## Referências

- **Product Vision**: `docs/product_vision.md`
- **Ubiquitous Language**: `docs/ubiquitous_language.md`
- **Domain Model**: `docs/domain.md`
- **Domain Events**: `docs/domain_events.md`
- **Modelo Lógico Detalhado**: `docs/data_model/logical_model.md`
- **DBML Identity**: `docs/data_model/dbdiagram/identity.dbml`
- **DBML Global**: `docs/data_model/dbdiagram/okomo_overview.dbml`

---

## Visualizando os Diagramas

### DBML Global

1. Acesse [dbdiagram.io](https://dbdiagram.io/)
2. Clique em "New Diagram"
3. Copie o conteúdo de `docs/data_model/dbdiagram/okomo_overview.dbml`
4. O diagrama será gerado automaticamente com todas as relações

### Exportando

DBDiagram permite exportar em vários formatos:
- SQL (criação de tabelas)
- PDF (para documentação)
- PNG (para slides)

---

## Governança do Modelo

- **Revisão**: Mudanças no modelo global são discutidas em design reviews
- **ADR**: Decisões de modelagem de dados importantes recebem um ADR
- **Changelog**: Mudanças significativas são registradas em `CHANGELOG.md`
- **Migrations**: Implementadas em Rails como fonte de verdade

---

**Última atualização:** Maio de 2026
