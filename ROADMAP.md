# Okomo — Roadmap

## 🎯 Objetivo

Construir uma plataforma SaaS de e-commerce para pequenos artesãos e empreendedores utilizando
Rails 8, PostgreSQL e Docker, com foco simultâneo em:

1. Desenvolver um produto real e funcional;
2. Consolidar conhecimentos avançados de engenharia de software;
3. Evoluir a arquitetura de forma incremental até um nível empresarial.

## Áreas de Conhecimento Desenvolvidas

- Domain-Driven Design (DDD)
- System Design
- Software Architecture
- Test-Driven Development (TDD)
- DevOps
- Observability
- Security Engineering
- Distributed Systems

---

# Fase 0 — Fundamentos de Produto e Arquitetura

## Produto
- [x] Criar `docs/product_vision.md`
- [x] Definir problema de negócio
- [x] Definir público-alvo
- [x] Definir proposta de valor
- [x] Definir diferenciais competitivos
- [x] Definir escopo do MVP

## Requisitos Não Funcionais
- [x] Criar `docs/non_functional_requirements.md`
- [x] Definir metas de performance
- [x] Definir requisitos de disponibilidade
- [x] Definir requisitos de segurança
- [x] Definir requisitos de escalabilidade
- [x] Definir requisitos de observabilidade
- [x] Definir objetivos de recuperação de falhas (RTO/RPO)

## Architecture Decision Records (ADR)
- [x] Criar `docs/adr/`
- [x] ADR-001: Monólito Modular
- [x] ADR-002: PostgreSQL como Banco de Dados Principal
- [x] ADR-003: UUID como Chaves Primárias
- [x] ADR-004: Pessimistic Locking para Inventory
- [x] ADR-005: Estratégia de Snapshot para OrderItem
- [x] ADR-006: Checkout Inicia a Reserva de Inventory
- [x] ADR-007: Variant é Responsável por Pricing e Inventory
- [x] ADR-008: Promotions como Bounded Context e Coupon como Entidade
- [x] ADR-009: Idempotência em Jobs de Expiração de Reserva
- [x] ADR-010: Namespacing de Rotas por Bounded Context
- [x] ADR-011: Estratégia de Testes por Camada
- [x] ADR-012: Estratégia de Criptografia de Dados em Repouso (ActiveRecord::Encryption)

## Estratégia de Testes
- [x] Criar `docs/testing_strategy.md`
- [x] Definir testes unitários, integração, contrato e end-to-end
- [x] Definir estratégia de factories, concorrência e idempotência

## Modelagem de Domínio
- [x] Criar `docs/ubiquitous_language.md`
- [x] Criar `docs/domain_events.md`
- [x] Mapear Domain Events prioritários

## Máquinas de Estado
- [x] Criar `docs/state_machines/`
- [x] Documentar estados de Order, Payment, Shipment e InventoryReservation

## API e Segurança
- [x] Criar `docs/api/`
- [x] Criar `docs/security.md`
- [x] Definir autenticação (Devise/JWT) e autorização (RBAC)
- [x] Definir rate limiting e proteção contra abuso

## Operação e Infraestrutura
- [x] Criar `docs/deployment.md`
- [x] Criar `docs/runbooks/`
- [x] Documentar deploy, rollback e resposta a incidentes

---

# Fase 1 — Fundamentos e Modelagem de Domínio

- [x] Refinar Linguagem Ubíqua e Bounded Contexts
- [x] Documentar casos de uso em `docs/use_cases/`
- [ ] Configurar Docker Compose completo (App, PostgreSQL, Redis, Sidekiq)
- [ ] Configurar RSpec, FactoryBot, RuboCop e GitHub Actions
- [ ] Implementar `BaseEntity` com suporte a UUID e Domain Events
- [ ] Implementar `BaseValueObject`
- [ ] Implementar `BaseService`
- [ ] Implementar `BaseRepository`

---

# Fase 2 — Domínio de Catálogo (Catalog)

- [ ] Criar `Product`
- [ ] Criar `Variant`
- [ ] Implementar `Pricing` em `Variant`
- [ ] Implementar SKU
- [ ] Implementar publicação de produtos
- [ ] Publicar `ProductCreated`, `VariantCreated` e `ProductPublished`

---

# Fase 3 — Domínio de Estoque (Inventory)

- [ ] Implementar `Inventory`
- [ ] Implementar `InventoryReservation`
- [ ] Implementar `available_quantity` e `reserved_quantity`
- [ ] Implementar `reserve!`
- [ ] Implementar `release!`
- [ ] Implementar `commit!`
- [ ] Implementar `Pessimistic Locking`
- [ ] Implementar expiração de reservas
- [ ] Implementar job de reconciliação

---

# Fase 4 — Domínio de Pedidos (Orders)

- [ ] Criar `Order`
- [ ] Criar `OrderItem`
- [ ] Implementar snapshots financeiros
- [ ] Implementar máquina de estados
- [ ] Implementar `CreateOrder`
- [ ] Implementar `AddItem`
- [ ] Implementar `RemoveItem`
- [ ] Implementar `CancelOrder`

---

# Fase 5 — Domínio de Promoções (Promotions)

- [ ] Criar `Promotion`
- [ ] Criar `Coupon`
- [ ] Criar `PromotionRule`
- [ ] Criar `Discount`
- [ ] Implementar `Specification Pattern`
- [ ] Implementar validade e limites de uso
- [ ] Implementar promoções automáticas
- [ ] Implementar `First Purchase`
- [ ] Implementar `Free Shipping`

---

# Fase 6 — Domínio de Checkout

- [ ] Implementar `StartCheckout`
- [ ] Reservar `Inventory`
- [ ] Aplicar `Promotions`
- [ ] Calcular totais
- [ ] Criar `Payment`
- [ ] Implementar compensação em falhas
- [ ] Implementar expiração de checkout

---

# Fase 7 — Domínio de Pagamentos (Payments)

- [ ] Criar `Payment`
- [ ] Implementar estados do pagamento
- [ ] Implementar `AuthorizePayment`
- [ ] Implementar `CapturePayment`
- [ ] Implementar `RefundPayment`
- [ ] Integrar webhooks com idempotência

---

# Fase 8 — Domínio de Entrega (Shipping)

- [ ] Criar `Shipment`
- [ ] Criar `ShippingMethod`
- [ ] Implementar cálculo de frete
- [ ] Implementar frete grátis
- [ ] Integrar com `Order` e `Promotions`

---

# Fase 9 — Observabilidade e Resiliência

- [ ] Implementar logs estruturados com `request_id`
- [ ] Configurar métricas (Prometheus/Grafana)
- [ ] Monitorar erros
- [ ] Implementar retries exponenciais
- [ ] Consolidar idempotência global

---

# Fase 10 — Evolução Arquitetural

- [ ] Implementar Event Store
- [ ] Implementar Event Handlers assíncronos
- [ ] Configurar Read Replicas no PostgreSQL
- [ ] Implementar cache avançado com Redis
- [ ] Planejar extração de Bounded Contexts para serviços independentes

---

## Critérios de Sucesso do Projeto

1. Cobertura de testes superior a 90% na lógica de domínio.
2. Zero Overselling comprovado por testes concorrentes.
3. Deploy automatizado e monitorado.
4. Conformidade com todos os ADRs definidos.
5. MVP funcional com fluxo completo:
   Catalog → Cart → Checkout → Promotions → Payments → Shipping.
6. Projeto demonstrando domínio em DDD, arquitetura, concorrência e resiliência.