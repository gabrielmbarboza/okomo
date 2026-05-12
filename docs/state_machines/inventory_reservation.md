# State Machine: InventoryReservation

## Visão Geral

Representa o ciclo de vida de uma reserva de estoque criada para um item de `Checkout`. Cada `InventoryReservation` está associada a um `Inventory` (de uma `Variant` específica) e a um `Checkout`. Seu estado controla os contadores `available_quantity` e `reserved_quantity` na entidade `Inventory`.

Esta entidade foi introduzida pelo ADR-009 para garantir idempotência nas operações de liberação de reserva executadas por background jobs.

---

## Estados

| Estado | Descrição |
|---|---|
| `reserved` | Quantidade reservada; `reserved_quantity` incrementado em `Inventory`. |
| `committed` | Reserva confirmada após pagamento; estoque efetivamente deduzido. |
| `released` | Reserva liberada por expiração ou falha; `available_quantity` restaurado. |

---

## Transições

```
(novo Checkout) ─────────► reserved
reserved ────────────────► committed     (evento PaymentConfirmed)
reserved ────────────────► released      (expiração do Checkout ou PaymentFailed)
```

---

## Impacto nos contadores de Inventory

| Transição | `available_quantity` | `reserved_quantity` |
|---|---|---|
| `→ reserved` | − quantity | + quantity |
| `→ committed` | sem alteração | − quantity |
| `→ released` | + quantity | − quantity |

---

## Regras e Invariantes

- A criação de uma `InventoryReservation` em `reserved` é feita dentro de uma transação com `SELECT ... FOR UPDATE` sobre o `Inventory`, conforme ADR-004.
- A transição `reserved → released` é executada por `ReleaseExpiredReservationJob`, que utiliza `FOR UPDATE SKIP LOCKED` para garantir idempotência, conforme ADR-009.
- Nenhuma `InventoryReservation` pode ser criada se `available_quantity < quantity` solicitada; o Checkout deve ser abortado nesse caso.
- Os estados `committed` e `released` são terminais; nenhuma transição é permitida a partir deles.
- Uma `Variant` pode ter múltiplas `InventoryReservations` ativas simultaneamente, desde que a soma de `quantity` não exceda `available_quantity` no momento de cada reserva.

---

## Eventos de Domínio Emitidos

| Transição | Evento |
|---|---|
| `→ reserved` | `InventoryReserved` |
| `→ committed` | `InventoryCommitted` |
| `→ released` | `InventoryReleased` |

---

## Referências

- ADR-004 — Pessimistic Locking para Inventory
- ADR-006 — Checkout inicia a reserva de Inventory
- ADR-009 — Idempotência em jobs de expiração de reserva
- State Machine: Payment
- State Machine: Order
