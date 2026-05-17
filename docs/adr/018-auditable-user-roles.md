# ADR-018: Roles e UserRole como Entidades Auditáveis

- **Status:** Accepted
- **Data:** 2026-05-17
- **Contexto:** Identity
- **Relacionado:** ADR-013 (Identity como Bounded Context), ADR-017 (Modelagem Evolutiva do Modelo de Dados)

---

## Contexto

O Identity domain precisa representar papéis de negócio sem perder histórico.
Um `User` confirmado sempre recebe `buyer`, pode solicitar `seller` via
`SellerProfile` e, em casos administrativos, pode receber `platform_admin`.

Uma modelagem simples de papéis como flags no `User` ou como relacionamento
sem histórico não atende às necessidades de auditoria, moderação e autorização.

---

## Decisão

- Roles globais da plataforma serão modeladas como um catálogo explícito (`Role`).
- A atribuição de papéis será representada por `UserRole`.
- `UserRole` preservará histórico completo de concessão e revogação.
- `buyer` será atribuído automaticamente após confirmação de e-mail e não poderá ser revogado.

---

## Consequências

`Role` passa a ser a fonte de nomes válidos de papéis da plataforma:
`buyer`, `seller` e `platform_admin`.

`UserRole` deixa de ser apenas uma associação técnica e passa a carregar
informações auditáveis como `granted_at`, `revoked_at`, `granted_by_user_id`,
`revoked_by_user_id` e `reason`.

Consultas de autorização devem considerar apenas `UserRole` sem `revoked_at`.
Consultas de auditoria podem reconstruir o histórico completo de papéis de um
`User`.

---

## Invariantes

- Todo `User` com e-mail confirmado deve possuir role ativo `buyer`.
- `buyer` é o papel fundacional da plataforma e não pode ser revogado.
- `seller` só deve ser concedido após aprovação de `SellerProfile`.
- `seller` deve ser revogado quando `SellerProfile` for suspenso.
- `platform_admin` deve ser concedido e revogado apenas por fluxo administrativo explícito.
