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
- [x] ADR-013: Identity como Bounded Context para User, Seller, Buyer
- [x] ADR-014: Autenticação Nativa Rails com has_secure_password e JWT
- [x] ADR-015: Custom Rails Generators para Domain Scaffolding
- [x] ADR-016: Política Contínua de Atualização de Ruby, Rails e Dependências
- [x] ADR-018: Roles e UserRole como Entidades Auditáveis
- [x] ADR-019: Infraestrutura Declarativa para Entidades de Domínio
- [x] ADR-020: Conformidade com a LGPD e governança de dados pessoais
- [x] ADR-022: Solid Queue como Backend Inicial de Background Jobs

## Estratégia de Testes
- [x] Criar `docs/testing_strategy.md`
- [x] Definir testes unitários, integração, contrato e end-to-end
- [x] Definir estratégia de factories, concorrência e idempotência

## Modelagem de Dados
- [x] Criar `docs/data_model/README.md`
- [x] Documentar modelo conceitual do Identity em `docs/data_model/conceptual_model.md`
- [x] Documentar modelo lógico para PostgreSQL em `docs/data_model/logical_model.md`
- [x] Definir convenções de nomenclatura em `docs/data_model/naming_conventions.md`
- [x] Gerar diagrama DBML para visualização em dbdiagram.io (`docs/data_model/dbdiagram/identity.dbml`)
- [x] Criar diagrama global consolidado (`docs/data_model/dbdiagram/okomo_overview.dbml`)
- [x] Documentar visão arquitetônica global em `docs/data_model/overview.md`
- [x] ADR-017: Modelagem Evolutiva do Modelo de Dados
- [ ] Refinar diagramas específicos por Bounded Context conforme implementação evolui
- [ ] Revisar o modelo ER antes de cada nova fase de desenvolvimento

## Modelagem de Domínio
- [x] Criar `docs/ubiquitous_language.md`
- [x] Criar `docs/domain_events.md`
- [x] Criar `docs/business_rules/`
- [x] Documentar regras de negócio por Bounded Context
- [x] Mapear Domain Events prioritários
- [x] Documentar termos do Identity domain (User, Role, UserRole, SellerProfile, buyer, seller, platform_admin)
- [x] Documentar estados de User (pending_confirmation, active, blocked, deactivated)
- [x] Documentar estados de SellerProfile (pending_review, approved, rejected, suspended)
- [x] Documentar eventos de Identity domain (UserRegistered, UserEmailConfirmed, RoleGranted, RoleRevoked, etc)
- [x] ADR-018: Roles e UserRole como Entidades Auditáveis

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

## Governança do Projeto
- [x] Documentar convenção de commits no README
- [x] Criar CODE_OF_CONDUCT.md
- [x] Criar CONTRIBUTING.md
- [ ] Configurar Dependabot ou Renovate para atualização automática de dependências
- [ ] Definir e implementar política contínua de atualização de Ruby, Rails e dependências (ADR-016)
- [ ] Documentar processo de upgrade e rollback em runbook

---

# Fase 1 — Fundamentos e Modelagem de Domínio

- [x] Refinar Linguagem Ubíqua e Bounded Contexts
- [x] Documentar casos de uso em `docs/use_cases/`
- [x] Documentar casos de uso do Identity em `docs/use_cases/identity/README.md`
- [x] Configurar Docker Compose completo (App, PostgreSQL e Solid Queue)
- [x] Configurar RSpec, FactoryBot, Faker, RuboCop, Brakeman, Bundler Audit e GitHub Actions
- [x] Implementar `BaseEntity` com suporte a UUID e Domain Events
- [x] Evoluir BaseEntity para suportar attributes e validações declarativas
- [x] Refatorar entidades existentes para usar infraestrutura declarativa
- [x] Implementar `BaseValueObject`
- [x] Implementar `BaseService`
- [ ] Implementar `BaseRepository`
- [x] Criar generators customizados para scaffolding de bounded contexts e artefatos de domínio

---

# Fase 2 — Identity e Access Management

## Documentação (Completa ✅)
- [x] Criar `docs/domain.md` seção Identity com agregados e casos de uso
- [x] Criar `docs/use_cases/identity/README.md` com todos os 10 casos de uso
- [x] Criar `docs/state_machines/user_state_machine.md` com diagrama e transições
- [x] Criar `docs/state_machines/seller_profile_state_machine.md` com diagrama e transições
- [x] Atualizar `docs/data_model/dbdiagram/identity.dbml` com estrutura auditável
- [x] Atualizar `docs/data_model/dbdiagram/okomo_overview.dbml`

## Implementação de Entidades de Domínio (Completa ✅)
- [x] Implementar entidades do domínio Identity (User, Role, UserRole, SellerProfile)
- [x] Criar testes unitários para o domínio Identity
- [x] Criar entidade `Identity::Entities::Role`
- [x] Criar entidade `Identity::Entities::UserRole` (auditável)
- [x] Criar entidade `Identity::Entities::User` (Aggregate Root)
- [x] Criar entidade `Identity::Entities::SellerProfile`
- [x] Criar testes unitários abrangentes para todas as entidades

## Implementação de Casos de Uso (Próxima Fase)
- [x] Implementar `RegisterUser`
- [x] Implementar confirmação de e-mail com concessão automática de role `buyer`
- [x] Implementar `AuthenticateUser`
- [x] Implementar geração e validação de JWT
- [x] Implementar `RequestPasswordRecovery` e `ResetPassword`
- [x] Implementar `RequestSellerApplication`
- [x] Implementar `ApproverSeller`, `RejectSeller` e `SuspendSeller`
- [ ] Implementar RBAC (buyer, seller, admin)
- [ ] Implementar `ReactivateSeller`

---

# Fase 3 — Domínio de Catálogo (Catalog)

- [ ] Criar `Product`
- [ ] Criar `Variant`
- [ ] Implementar `Pricing` em `Variant`
- [ ] Implementar SKU
- [ ] Implementar publicação de produtos
- [ ] Publicar `ProductCreated`, `VariantCreated` e `ProductPublished`

---

# Fase 5 — Domínio de Estoque (Inventory)

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

# Fase 5 — Domínio de Pedidos (Orders)

- [ ] Criar `Order`
- [ ] Criar `OrderItem`
- [ ] Implementar snapshots financeiros
- [ ] Implementar máquina de estados
- [ ] Implementar `CreateOrder`
- [ ] Implementar `AddItem`
- [ ] Implementar `RemoveItem`
- [ ] Implementar `CancelOrder`

---

# Fase 6 — Domínio de Promoções (Promotions)

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

# Fase 7 — Domínio de Checkout

- [ ] Implementar `StartCheckout`
- [ ] Reservar `Inventory`
- [ ] Aplicar `Promotions`
- [ ] Calcular totais
- [ ] Criar `Payment`
- [ ] Implementar compensação em falhas
- [ ] Implementar expiração de checkout

---

# Fase 9 — Domínio de Pagamentos (Payments)

- [ ] Criar `Payment`
- [ ] Implementar estados do pagamento
- [ ] Implementar `AuthorizePayment`
- [ ] Implementar `CapturePayment`
- [ ] Implementar `RefundPayment`
- [ ] Integrar webhooks com idempotência

---

# Fase 9 — Domínio de Entrega (Shipping)

- [ ] Criar `Shipment`
- [ ] Criar `ShippingMethod`
- [ ] Implementar cálculo de frete
- [ ] Implementar frete grátis
- [ ] Integrar com `Order` e `Promotions`

---

# Fase 10 — Observabilidade e Resiliência

- [ ] Implementar logs estruturados com `request_id`
- [ ] Configurar métricas (Prometheus/Grafana)
- [ ] Monitorar erros
- [ ] Implementar retries exponenciais
- [ ] Consolidar idempotência global

---

# Fase 12 — Evolução Arquitetural

- [ ] Implementar Event Store
- [ ] Implementar Event Handlers assíncronos
- [ ] Configurar Read Replicas no PostgreSQL
- [ ] Implementar cache avançado com Redis
- [ ] Avaliar migração para Sidekiq conforme crescimento da plataforma
- [ ] Introduzir Redis para cache distribuído e otimizações
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
