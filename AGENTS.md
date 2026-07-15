# Okomo — Project Instructions

Okomo is a modular-monolith Rails 8 e-commerce SaaS built with DDD. See [architecture.md](architecture.md), [ROADMAP.md](ROADMAP.md), and [docs/](docs/) for domain context before making non-trivial changes.

## Test-Driven Development (mandatory)

All domain code (`app/domains/**` — entities, value objects, services, repositories, events) must be written TDD-first:

1. **Red** — write a failing spec first, describing the behavior.
2. **Green** — write the minimum code to pass it.
3. **Refactor** — clean up while keeping the suite green.

Never write domain implementation code before its spec exists. Run `bundle exec rspec` (or the relevant file) before considering any change complete. See [docs/testing_strategy.md](docs/testing_strategy.md) for layer-specific guidance and the 90% coverage target on `app/models` and `app/domains`.

## Commit Convention (mandatory)

All commits use [Conventional Commits](https://www.conventionalcommits.org/), written in **English**.

```
<type>(<scope>): <description>

<body>
```

- **Description:** imperative mood, lowercase, no period, max 72 chars.
- **Scope:** the bounded context or area (`identity`, `catalog`, `inventory`, `orders`, `promotions`, `checkout`, `payments`, `shipping`, `shared`, `adr`, `ci`, `infra`, etc).
- **Body is mandatory, no exceptions:** one bullet per file or logical change, including specs and doc updates.
- **Types:** `feat`, `fix`, `docs`, `refactor`, `test`, `chore`, `perf`, `ci`, `revert`.

Example:

```
feat(catalog): implement product creation use case

- Add Catalog::Entities::Product with pricing validation
- Add Catalog::Services::CreateProduct
- Add ProductCreated domain event
- Add unit tests for Product entity and CreateProduct service
- Update docs/domain_events.md with ProductCreated
```

Only commit when the user explicitly asks.
