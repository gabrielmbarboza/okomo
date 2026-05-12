# Okomo — Roadmap

## 🎯 Objetivo

Construir um marketplace funcional para pequenos artesãos e empreendedores utilizando
Rails 8, PostgreSQL e Docker, com foco na evolução técnica para um nível mais alto de senioridade.

## Áreas de Conhecimento Desenvolvidas

- Domain-Driven Design (DDD)
- System Design
- Software Architecture
- Test-Driven Development (TDD)
- DevOps
- Observability

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
- [x] ADR-001: Monolito Modular
- [x] ADR-002: PostgreSQL como Banco de Dados Principal
- [x] ADR-003: Chaves Primárias UUID
- [x] ADR-004: Locking Pessimista para Estoque
- [x] ADR-005: Estratégia de Snapshots para OrderItem
- [x] ADR-006: Checkout Inicia Reserva de Estoque
- [x] ADR-007: Variant gerencia Pricing e Inventory
- [x] ADR-008: Specification Pattern para regras de Coupon
- [x] ADR-009: Idempotência em jobs de expiração de reserva
- [x] ADR-010: Namespacing de rotas por bounded context
- [x] ADR-011: Estratégia de testes por camada
- [x] ADR-012: Estratégia de Criptografia de Dados em Repouso (ActiveRecord::Encryption)

## Estratégia de Testes
- [x] Criar `docs/testing_strategy.md`
- [x] Definir testes unitários e de integração
- [x] Definir testes de contrato e end-to-end
- [x] Definir estratégia de factories, concorrência e idempotência

## Eventos de Domínio
- [x] Criar `docs/domain_events.md`
- [x] Mapear OrderCreated, InventoryReserved, PaymentCompleted e outros

## Máquinas de Estado
- [x] Criar `docs/state_machines/`
- [x] Documentar estados de Order, Payment, Shipment e InventoryReservation

## API e Segurança
- [x] Criar `docs/api/`
- [x] Criar `docs/security.md`
- [x] Definir autenticação (Devise/JWT) e autorização (RBAC)
- [x] Definir rate limiting e proteção contra fraude/abuso

## Operação e Infraestrutura
- [x] Criar `docs/deployment.md`
- [x] Criar `docs/runbooks/`
- [x] Documentar processo de deploy (Docker/Thruster) e rollback
- [x] Documentar resposta a incidentes (Pagamento e Estoque)

---

# Fase 1 — Fundamentos e Modelagem de Domínio

- [ ] Refinar linguagem ubíqua e Bounded Contexts
- [ ] Documentar casos de uso e fluxo de checkout
- [ ] Configurar ambiente Docker Compose completo (App, DB, Redis, Sidekiq)
- [ ] Configurar RSpec, RuboCop e CI (GitHub Actions)
- [ ] Implementar BaseEntity para suporte nativo a UUID e Domain Events

---

# Fase 2 — Domínio de Catálogo (Catalog)

- [ ] Criar Product e Variant
- [ ] Definir SKU e Pricing por Variant
- [ ] Implementar casos de uso do catálogo
- [ ] Publicar eventos `ProductCreated` e `ProductUpdated`

---

# Fase 3 — Domínio de Estoque (Inventory)

- [ ] Implementar Inventory (`available_quantity` e `reserved_quantity`)
- [ ] Implementar Pessimistic Locking para prevenir overselling
- [ ] Implementar Inventory Reservation e expiração de reservas
- [ ] Implementar Job de Reconciliação de Estoque baseado no Runbook

---

# Fase 4 — Domínio de Pedidos (Orders)

- [ ] Criar Order e OrderItem
- [ ] Implementar persistência de snapshots financeiros
- [ ] Implementar transições de estado (AASM ou similar)
- [ ] Criar CRUD de pedidos (AddItem, RemoveItem, CancelOrder)

---

# Fase 5 — Domínio de Checkout

- [ ] Implementar Iniciar Checkout com reserva automática de estoque
- [ ] Integrar aplicação de Coupon
- [ ] Calcular totais e disparar processamento de Payment
- [ ] Implementar compensação: liberar reservas em falha ou abandono

---

# Fase 6 — Domínio de Pagamentos (Payments)

- [ ] Criar entidade Payment e seus estados
- [ ] Implementar Authorize, Confirm e Refund Payment
- [ ] Integrar webhooks do gateway com tratamento de idempotência

---

# Fase 7 — Domínio de Entrega (Shipping)

- [ ] Criar Shipment e definir estratégias de frete
- [ ] Implementar regras de frete grátis
- [ ] Integrar Shipment com Order e fluxos de Coupon

---

# Fase 8 — Domínio de Promoções (Coupons)

- [ ] Criar Coupon e regras de desconto (Specification Pattern)
- [ ] Implementar validade, limites de uso e regras por categoria/variant
- [ ] Implementar regra de First Purchase

---

# Fase 9 — Observabilidade e Resiliência

- [ ] Implementar logging estruturado com request_id correlacionado
- [ ] Configurar métricas (Prometheus/Grafana) e monitoramento de erros
- [ ] Implementar estratégia de retry exponencial e idempotência global

---

# Fase 10 — Evolução Arquitetural

- [ ] Implementar Domain Events Store e Event Handlers assíncronos
- [ ] Configurar Read Replicas no PostgreSQL
- [ ] Implementar estratégia de cache agressiva com Redis
- [ ] Planejar extração de Bounded Contexts para serviços independentes

---

## Critérios de Sucesso do Projeto

1.  Cobertura de testes > 90% em lógica de domínio.
2.  Resiliência comprovada (Zero Overselling).
3.  Deploy automatizado e monitorado.
4.  Conformidade técnica com os padrões ADR definidos.