# ADR-001: Monólito Modular

## Status
Aceito

## Contexto
O Okomo será iniciado como um SaaS de e-commerce com múltiplos domínios de negócio, como Catalog, Inventory, Order, Checkout, Payment, Shipment e Coupon.

## Decisão
A aplicação será construída como um Monólito Modular, utilizando Rails 8 e separação explícita por domínios em `app/domains`.

## Consequências
### Positivas
- Simplicidade operacional
- Baixo custo inicial
- Evolução incremental
- Fronteiras claras entre domínios

### Negativas
- Necessidade de disciplina arquitetural
- Risco de acoplamento se os módulos não forem respeitados
