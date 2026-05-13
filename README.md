# Okomo — Marketplace Platform

API-only Ruby on Rails 8 application built with Domain-Driven Design (DDD) principles.

## 🛠 Documentação Técnica e Governança

Para detalhes aprofundados sobre a arquitetura, segurança e operações, consulte os documentos na pasta `docs/`:

- [**Roadmap do Projeto**](ROADMAP.md) - Status atual e planejamento das 10 fases.
- [**Modelo de Domínio**](docs/domain.md) - Visão conceitual e bounded contexts.
- [**Linguagem Ubíqua**](docs/ubiquitous_language.md) - Termos de negócio padronizados.
- [**Casos de Uso**](docs/use_cases/) - Fluxos detalhados por bounded context.
- [**Segurança e LGPD**](docs/security.md) - Padrões de autenticação, RBAC e criptografia.
- [**Estratégia de Testes**](docs/testing_strategy.md) - Pirâmide de testes e padrões de qualidade.
- [**Deployment e Infraestrutura**](docs/deployment.md) - Docker, Thruster, S3 e CI/CD.
- [**Runbook Operacional**](docs/runbooks/operational_runbook.md) - Procedimentos de crise e manutenção.
- [**Eventos de Domínio**](docs/domain_events.md) - Mapeamento da comunicação entre contextos.
- [**Architecture Decision Records (ADR)**](docs/adr/) - Registro de decisões arquiteturais fundamentais.

---

## 🚀 Stack

- **Ruby on Rails 8.1** (API-only)
- **PostgreSQL 16** (UUID primary keys)
- **Redis 7** (caching + background jobs)
- **Sidekiq** (prepared for async processing)
- **Docker** + **Docker Compose**
- **Thruster** (Rails 8 acceleration proxy)

---

## 🏁 Getting Started

### Prerequisites

- Docker & Docker Compose

### Setup

```bash
# 1. Clone the repository
git clone <repo-url> && cd okomo

# 2. Copy environment variables
cp .env.example .env

# 3. Build and start all services
docker-compose up --build

# 4. Create and migrate the database (in another terminal)
docker-compose exec app bundle exec rails db:create db:migrate

# 5. Access the API
curl http://localhost:3000/up
```

### Running with Sidekiq

```bash
docker-compose --profile with-sidekiq up
```

### Useful Commands

```bash
# Rails console
docker-compose exec app bundle exec rails console

# Run migrations
docker-compose exec app bundle exec rails db:migrate

# Stop all services
docker-compose down

# Stop and remove volumes (reset data)
docker-compose down -v
```

---

## 🏗 Architecture

This project follows a **modular monolith** approach with lightweight **Domain-Driven Design** principles.

### Directory Structure

```text
app/
├── controllers/          # Thin controllers (orchestration only)
├── models/               # Thin ActiveRecord models (data access only)
└── domains/              # Business logic lives here
    ├── shared/           # Shared kernel - base classes and utilities
    │   ├── entities/     # BaseEntity with UUID support and equality
    │   ├── value_objects/ # BaseValueObject with immutability
    │   ├── services/     # BaseService with delegation pattern
    │   └── repositories/ # BaseRepository for data access
    ├── catalog/
    │   ├── services/     # Business operations
    │   ├── entities/     # POROs (not ActiveRecord)
    │   ├── value_objects/ # Immutable value types
    │   └── repositories/ # Data access abstractions
    ├── orders/
    ├── payments/
    ├── shipping/
    └── inventory/
        ├── services/
        ├── entities/
        ├── value_objects/
        └── repositories/
```

### Architectural Rules

1. **No fat models** — ActiveRecord models are for data access only.
2. **No business logic in controllers** — Controllers orchestrate requests.
3. **Domain services** — All business logic lives in `app/domains/<domain>/services/`.
4. **Entities are POROs** — Not ActiveRecord, just plain Ruby objects.
5. **Value objects are immutable** — Frozen after initialization, compared by value.
6. **Domain Events** — Efeitos colaterais entre domínios devem ser tratados via eventos para garantir o desacoplamento.
7. **Shared Kernel** — Base classes provide common functionality across domains.
8. **Repository Pattern** — Data access abstracted through repositories.

### Example Usage

```ruby
# Controller (thin — orchestrates only)
class Api::V1::OrdersController < ApplicationController
  def create
    result = Orders::Services::CreateOrder.call(order_params)

    if result.success?
      render json: result.data, status: :created
    else
      render json: { errors: result.errors }, status: :unprocessable_entity
    end
  end
end

# Domain Service (business logic)
class Orders::Services::CreateOrder < Shared::Services::BaseService
  def initialize(params)
    @params = params
  end

  def call
    # validate, create order, reserve inventory, etc.
  end
end

# Domain Entity (business object)
class Orders::Entities::Order < Shared::Entities::BaseEntity
  attr_reader :id, :customer_id, :status, :total_amount
  
  def initialize(id:, customer_id:, status: 'pending', total_amount: 0)
    super(id: id, customer_id: customer_id, status: status, total_amount: total_amount)
  end
end

# Domain Value Object (immutable)
class Orders::ValueObjects::Money < Shared::ValueObjects::BaseValueObject
  attr_reader :amount, :currency
  
  def initialize(amount:, currency: 'BRL')
    super(amount: amount, currency: currency)
  end
end
```

---

## ⚙️ Configuration

| Setting | Value |
|---------|-------|
| Timezone | America/Sao_Paulo |
| Default locale | pt-BR |
| Primary key | UUID |
| Job adapter | Sidekiq |
| API mode | true |
| Encryption | ActiveRecord::Encryption (AES-256-GCM) |

---

## 🛡️ Segurança e Resiliência

- **Pessimistic Locking**: Aplicado no domínio de `Inventory` para garantir Zero Overselling.
- **Idempotência**: Garantida em todos os Jobs do Sidekiq e processamento de Webhooks.
- **Auditoria**: Snapshot financeiro em `OrderItem` para garantir imutabilidade de preços históricos.

## Environment Variables

See [.env.example](.env.example) for all available configuration options.

## License

Proprietary. Todos os direitos reservados.