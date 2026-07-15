# Okomo — Marketplace Platform

API-only Ruby on Rails 8 application built with Domain-Driven Design (DDD) principles.

## 🛠 Technical Documentation & Governance

For in-depth details about architecture, security, and operations, consult the documents in the `docs/` folder:

- [**Project Roadmap**](ROADMAP.md) - Current status and 10-phase planning.
- [**Domain Model**](docs/domain.md) - Conceptual vision and bounded contexts.
- [**Ubiquitous Language**](docs/ubiquitous_language.md) - Standardized business terms (PT-BR).
- [**Use Cases**](docs/use_cases/) - Detailed flows by bounded context.
- [**Security & Privacy**](docs/security.md) - Authentication, RBAC, and encryption patterns.
- [**Testing Strategy**](docs/testing_strategy.md) - Testing pyramid and quality patterns.
- [**Data Model**](docs/data_model/) - Conceptual, logical, and DBML diagrams (PostgreSQL).
  - [**Global Data Model Overview**](docs/data_model/overview.md) - Architectural view of all Bounded Contexts.
  - [**Global DBML Diagram**](docs/data_model/dbdiagram/okomo_overview.dbml) - Consolidated ER model. Visualize at [dbdiagram.io](https://dbdiagram.io).
- [**Deployment & Infrastructure**](docs/deployment.md) - Docker, Thruster, S3, and CI/CD.
- [**Operational Runbook**](docs/runbooks/operational_runbook.md) - Crisis procedures and maintenance.
- [**Domain Events**](docs/domain_events.md) - Inter-context communication mapping.
- [**Architecture Decision Records (ADR)**](docs/adr/) - Fundamental architectural decisions registry.
- [**Continuous Upgrade Policy**](docs/adr/ADR-016-continuous-upgrade-policy.md) - Ruby, Rails, and dependency version management strategy.

---

## 🚀 Stack

- **Ruby on Rails 8.1** (API-only)
- **PostgreSQL 16** (UUID primary keys)
- **Solid Queue** (backend inicial de background jobs via Active Job)
- **Redis 7** (opcional para cache distribuído e cenários futuros de escala)
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

# 3. Build and start all required services
docker-compose up --build

# 4. Create and prepare the application and Solid Queue databases (in another terminal)
docker-compose exec okomo_api bundle exec rails db:prepare

# 5. Access the API
curl http://localhost:3000/up
```

### Running Solid Queue Workers

```bash
docker-compose --profile with-jobs up
```

Os jobs devem ser criados via Active Job. O backend inicial é Solid Queue, mantendo Redis como dependência opcional para cache futuro ou cenários de escala.

### Useful Commands

```bash
# Rails console
docker-compose exec okomo_api bundle exec rails console

# Run migrations
docker-compose exec okomo_api bundle exec rails db:migrate

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
6. **Domain Events** — Side effects between domains should be handled via events and Active Job handlers to ensure decoupling.
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

### Custom Generators

Okomo includes custom generators to automate the creation of bounded contexts and domain artifacts, ensuring architectural consistency and reducing repetitive work.

#### Create a Bounded Context

```bash
bin/rails generate domain Identity
```

Creates the complete directory structure for the bounded context:

```
app/domains/identity/
├── identity.rb
├── entities/
├── services/
├── repositories/
├── value_objects/
├── events/
├── specifications/
└── policies/
```

#### Create an Entity

```bash
bin/rails generate domain_entity Identity User
```

Generates `app/domains/identity/entities/user.rb` inheriting from `Shared::Entities::BaseEntity`.

#### Create a Service

```bash
bin/rails generate domain_service Identity RegisterUser
```

Generates `app/domains/identity/services/register_user.rb` inheriting from `Shared::Services::BaseService`.

#### Create a Value Object

```bash
bin/rails generate domain_value_object Orders Money
```

Generates `app/domains/orders/value_objects/money.rb` inheriting from `Shared::ValueObjects::BaseValueObject`.

#### Create a Repository

```bash
bin/rails generate domain_repository Orders OrderRepository
```

Generates `app/domains/orders/repositories/order_repository.rb`.

#### Create a Domain Event

```bash
bin/rails generate domain_event Orders OrderCreated
```

Generates `app/domains/orders/events/order_created.rb` with payload and timestamp.

---

## ⚙️ Configuration

| Setting | Value |
|---------|-------|
| Timezone | America/Sao_Paulo |
| Default locale | pt-BR |
| Primary key | UUID |
| Job adapter | Active Job com Solid Queue |
| API mode | true |
| Encryption | ActiveRecord::Encryption (AES-256-GCM) |

---

## 🛡️ Security & Resilience

- **Pessimistic Locking**: Applied in the `Inventory` domain to ensure Zero Overselling.
- **Idempotency**: Guaranteed in all Active Job jobs and webhook processing, independentemente do backend de fila.
- **Audit**: Financial snapshot in `OrderItem` to ensure historical price immutability.

---

## Git Commit Convention

This project follows the [Conventional Commits](https://www.conventionalcommits.org/) specification to standardize commit messages and facilitate reading the change history. All commits are written in **English**.

The structure is:

```
<type>(<scope>): <description>

<body>
```

- **Description:** imperative mood, lowercase, no period, max 72 chars.
- **Body is mandatory:** one bullet per file or logical change made in the commit — no exceptions, even for small commits.

### Common Types

- `feat`: New feature
- `fix`: Bug fix
- `docs`: Documentation changes
- `test`: Test additions or changes
- `refactor`: Code refactoring
- `chore`: Maintenance or configuration tasks

### Example

```
feat(catalog): implement product creation use case

- Add Catalog::Entities::Product with pricing validation
- Add Catalog::Services::CreateProduct
- Add ProductCreated domain event
- Add unit tests for Product entity and CreateProduct service
- Update docs/domain_events.md with ProductCreated
```

---

## Project Governance

This project follows governance standards to ensure a healthy and sustainable collaborative environment.

- [**Code of Conduct**](CODE_OF_CONDUCT.md) - Behavior guidelines for all participants.
- [**Contribution Guide**](CONTRIBUTING.md) - Instructions for contributing to the project.
- [**Security Policy**](docs/security.md) - Security and privacy standards.

All participants are expected to act with respect, empathy, and professionalism.

---

## Environment Variables

See [.env.example](.env.example) for all available configuration options.

## License

Proprietary. All rights reserved.
