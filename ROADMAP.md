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

- [ ] Criar `docs/product_vision.md`
- [ ] Definir problema de negócio
- [ ] Definir público-alvo
- [ ] Definir proposta de valor
- [ ] Definir diferenciais competitivos
- [ ] Definir escopo do MVP

## Requisitos Não Funcionais

- [ ] Criar `docs/non_functional_requirements.md`
- [ ] Definir metas de performance
- [ ] Definir requisitos de disponibilidade
- [ ] Definir requisitos de segurança
- [ ] Definir requisitos de escalabilidade
- [ ] Definir requisitos de observabilidade
- [ ] Definir objetivos de recuperação de falhas (RTO/RPO)

## Architecture Decision Records (ADR)

- [ ] Criar `docs/adr/`
- [ ] ADR-001: Monolito Modular
- [ ] ADR-002: PostgreSQL como Banco de Dados Principal
- [ ] ADR-003: Chaves Primárias UUID
- [ ] ADR-004: Locking Pessimista para Estoque
- [ ] ADR-005: Estratégia de Snapshots para OrderItem
- [ ] ADR-006: Checkout Inicia Reserva de Estoque
- [ ] ADR-007: Variant gerencia Pricing e Inventory

## Estratégia de Testes

- [ ] Criar `docs/testing_strategy.md`
- [ ] Definir testes unitários
- [ ] Definir testes de integração
- [ ] Definir testes de API
- [ ] Definir testes end-to-end
- [ ] Definir estratégia de factories e fixtures

## Eventos de Domínio

- [ ] Criar `docs/domain_events.md`
- [ ] Mapear OrderCreated
- [ ] Mapear CheckoutStarted
- [ ] Mapear InventoryReserved
- [ ] Mapear PaymentAuthorized
- [ ] Mapear PaymentFailed
- [ ] Mapear OrderPaid
- [ ] Mapear ShipmentCreated

## Máquinas de Estado

- [ ] Criar `docs/state_machines/`
- [ ] Documentar estados de Order
- [ ] Documentar estados de Payment
- [ ] Documentar estados de Shipment
- [ ] Documentar estados de InventoryReservation

## API e Segurança

- [ ] Criar `docs/api/`
- [ ] Criar `docs/security.md`
- [ ] Definir autenticação
- [ ] Definir autorização
- [ ] Definir rate limiting
- [ ] Definir proteção contra fraude e abuso

## Operação e Infraestrutura

- [ ] Criar `docs/deployment.md`
- [ ] Criar `docs/runbooks/`
- [ ] Documentar processo de deploy
- [ ] Documentar rollback
- [ ] Documentar resposta a incidentes
- [ ] Documentar troubleshooting de pagamentos e estoque

## Planejamento do Produto

- [ ] Revisar `ROADMAP.md`
- [ ] Priorizar backlog do MVP
- [ ] Definir critérios de sucesso do projeto

---

# Fase 1 — Fundamentos e Modelagem de Domínio

- [ ] Refinar linguagem ubíqua
- [ ] Definir bounded contexts
- [ ] Documentar casos de uso
- [ ] Documentar fluxo de checkout
- [ ] Documentar lifecycle de Inventory
- [ ] Configurar RSpec
- [ ] Configurar RuboCop
- [ ] Configurar integração contínua (CI)

---

# Fase 2 — Domínio de Catálogo

- [ ] Criar Product
- [ ] Criar Variant
- [ ] Definir SKU
- [ ] Definir preço por Variant
- [ ] Criar casos de uso do catálogo

---

# Fase 3 — Domínio de Estoque

- [ ] Criar Inventory
- [ ] Implementar `available_quantity`
- [ ] Implementar `reserved_quantity`
- [ ] Prevenir overselling
- [ ] Implementar Inventory Reservation
- [ ] Implementar expiração de reservas
- [ ] Implementar Pessimistic Locking

---

# Fase 4 — Domínio de Pedidos

- [ ] Criar Order
- [ ] Criar OrderItem
- [ ] Persistir snapshots financeiros
- [ ] Implementar transições de estado
- [ ] Persistir totais
- [ ] Criar CreateOrder
- [ ] Criar AddItem
- [ ] Criar RemoveItem
- [ ] Criar CancelOrder

---

# Fase 5 — Domínio de Checkout

- [ ] Iniciar Checkout
- [ ] Reservar estoque
- [ ] Aplicar Coupon
- [ ] Calcular totais
- [ ] Processar Payment
- [ ] Liberar reservas em caso de falha
- [ ] Expirar reservas abandonadas

---

# Fase 6 — Domínio de Pagamentos

- [ ] Criar Payment
- [ ] Implementar estados de pagamento
- [ ] Authorize Payment
- [ ] Confirm Payment
- [ ] Refund Payment

---

# Fase 7 — Domínio de Entrega

- [ ] Criar Shipment
- [ ] Definir estratégias de frete
- [ ] Implementar frete grátis
- [ ] Integrar Shipment com Order
- [ ] Integrar Shipment com Coupon

---

# Fase 8 — Domínio de Promoções

- [ ] Criar Coupon
- [ ] Criar regras de desconto
- [ ] Implementar regras por categoria
- [ ] Implementar regras por Variant
- [ ] Implementar First Purchase
- [ ] Implementar validade

---

# Fase 9 — Observabilidade e Resiliência

- [ ] Implementar logging estruturado
- [ ] Implementar métricas
- [ ] Implementar monitoramento de erros
- [ ] Implementar idempotência
- [ ] Implementar estratégia de retry
- [ ] Implementar jobs assíncronos

---

# Fase 10 — Evolução Arquitetural

- [ ] Implementar Domain Events
- [ ] Estudar arquitetura orientada a eventos
- [ ] Configurar Read Replicas
- [ ] Implementar estratégia de cache
- [ ] Implementar processamento assíncrono
- [ ] Planejar futura extração de serviços
