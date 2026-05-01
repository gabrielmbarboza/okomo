# Okomo — Marketplace Platform

API-only Ruby on Rails 8 application built with Domain-Driven Design (DDD) principles.

## Stack

- **Ruby on Rails 8.1** (API-only)
- **PostgreSQL 16** (UUID primary keys)
- **Redis 7** (caching + background jobs)
- **Sidekiq** (prepared for async processing)
- **Docker** + **Docker Compose**

## Getting Started

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

## Architecture

This project follows a **modular monolith** approach with lightweight **Domain-Driven Design** principles.

### Directory Structure

```
app/
├── controllers/          # Thin controllers (orchestration only)
├── models/               # Thin ActiveRecord models (data access only)
└── domains/              # Business logic lives here
    ├── catalog/
    │   ├── services/     # Business operations
    │   ├── entities/     # POROs (not ActiveRecord)
    │   ├── value_objects/ # Immutable value types
    │   └── repositories/ # Data access abstractions
    ├── orders/
    │   ├── services/
    │   ├── entities/
    │   ├── value_objects/
    │   └── repositories/
    ├── payments/
    │   ├── services/
    │   ├── entities/
    │   ├── value_objects/
    │   └── repositories/
    ├── shipping/
    │   ├── services/
    │   ├── entities/
    │   ├── value_objects/
    │   └── repositories/
    └── inventory/
        ├── services/
        ├── entities/
        ├── value_objects/
        └── repositories/
```

### Architectural Rules

1. **No fat models** — ActiveRecord models are for data access only
2. **No business logic in controllers** — Controllers orchestrate requests
3. **Domain services** — All business logic lives in `app/domains/<domain>/services/`
4. **Entities are POROs** — Not ActiveRecord, just plain Ruby objects
5. **Value objects are immutable** — Frozen after initialization, compared by value

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
class Orders::Services::CreateOrder < Orders::Services::BaseService
  def initialize(params)
    @params = params
  end

  def call
    # validate, create order, reserve inventory, etc.
  end
end
```

## Configuration

| Setting | Value |
|---------|-------|
| Timezone | America/Sao_Paulo |
| Default locale | pt-BR |
| Primary key | UUID |
| Job adapter | Sidekiq |
| API mode | true |

## Environment Variables

See [.env.example](.env.example) for all available configuration options.

## License

Proprietary.
