# ADR-013 — Identity como Bounded Context para User, Seller e Buyer

- **Status:** Accepted
- **Data:** 2026-05-12

---

## Contexto

O Okomo precisa representar os seguintes conceitos relacionados à identidade e aos papéis de negócio:

- `User`: conta de acesso utilizada para autenticação e autorização.
- `Seller`: papel de negócio responsável por vender produtos no marketplace.
- `Buyer`: papel de negócio responsável por realizar compras no marketplace.

Esses conceitos serão utilizados por diversos Bounded Contexts, incluindo:

- `Catalog`
- `Cart`
- `Checkout`
- `Orders`
- `Promotions`
- `Payments`
- `Shipping`

Era necessário definir em qual contexto esses conceitos seriam modelados e como os demais domínios se relacionariam com eles.

---

## Decisão

O Okomo adotará um Bounded Context denominado `Identity`, responsável por:

- autenticação;
- autorização;
- gerenciamento de contas;
- modelagem dos papéis `Seller` e `Buyer`.

Os demais Bounded Contexts se relacionarão com o contexto `Identity` exclusivamente por identificadores (`user_id`, `seller_id`, `buyer_id`), evitando dependência direta entre objetos de domínios distintos.

---

## Modelo Conceitual

```text
User
 ├── has_one Seller (optional)
 └── has_one Buyer  (optional)