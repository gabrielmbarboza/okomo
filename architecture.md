# Architecture - Okomo

## Style
Monolithic modular application

## Stack
- Ruby on Rails (API-only)
- PostgreSQL
- Redis (future use for caching and background jobs)

## Domains
- Catalog
- Orders
- Payments

## Key Decisions

### Monolith First
- Simpler to build and maintain
- Easier deployment

### Future Evolution
- Extract services when needed (e.g., Payments)

### Concurrency
- Use database-level locking (pessimistic initially)
