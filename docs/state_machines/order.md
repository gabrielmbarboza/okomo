# State Machine: Order

## Visão Geral

Representa o ciclo de vida de um pedido desde a sua criação até a conclusão ou cancelamento. O estado da `Order` reflete o avanço do processo transacional, sendo influenciado pelos estados de `Payment` e `Shipment`.

---

## Estados

| Estado | Descrição |
|---|---|
| `draft` | Order criada durante o Checkout, ainda não confirmada. |
| `pending_payment` | Checkout concluído; aguardando confirmação do pagamento. |
| `paid` | Pagamento confirmado pelo gateway; estoque comprometido. |
| `processing` | Seller iniciou a preparação do pedido para envio. |
| `shipped` | Shipment despachado; rastreio disponível para o Buyer. |
| `delivered` | Entrega confirmada. |
| `cancelled` | Order cancelada antes do envio. |
| `refunded` | Pagamento estornado após cancelamento pós-cobrança. |

---

## Transições

```
draft ──────────────────► pending_payment
pending_payment ─────────► paid
pending_payment ─────────► cancelled        (pagamento recusado ou timeout do Checkout)
paid ────────────────────► processing
paid ────────────────────► cancelled        (cancelamento pelo Seller antes do envio)
cancelled ───────────────► refunded         (quando já houve cobrança)
processing ──────────────► shipped
shipped ─────────────────► delivered
```

---

## Regras e Invariantes

- Uma `Order` só avança para `paid` após o evento `PaymentConfirmed` emitido pelo contexto `Payment`.
- A transição para `cancelled` a partir de `paid` exige que nenhum `Shipment` associado esteja em trânsito.
- A transição para `refunded` é iniciada pelo contexto `Payment` e não pode ser revertida.
- Os estados `delivered`, `cancelled` e `refunded` são terminais; nenhuma transição é permitida a partir deles.
- A transição `paid → processing` é responsabilidade do Seller e ocorre fora do fluxo automatizado.

---

## Eventos de Domínio Emitidos

| Transição | Evento |
|---|---|
| `→ paid` | `OrderPaid` |
| `→ cancelled` | `OrderCancelled` |
| `→ refunded` | `OrderRefunded` |
| `→ shipped` | `OrderShipped` |
| `→ delivered` | `OrderDelivered` |

---

## Referências

- ADR-006 — Checkout inicia a reserva de Inventory
- State Machine: Payment
- State Machine: Shipment
- State Machine: InventoryReservation
