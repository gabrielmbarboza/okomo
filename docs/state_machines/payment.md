# State Machine: Payment

## Visão Geral

Representa o ciclo de vida de uma tentativa de pagamento associada a um `Checkout`. O `Payment` é criado no momento em que o Buyer confirma o pedido e é processado de forma assíncrona pelo gateway externo. Seu estado determina diretamente as transições da `Order` e da `InventoryReservation`.

---

## Estados

| Estado | Descrição |
|---|---|
| `pending` | Payment criado; aguardando processamento pelo gateway. |
| `processing` | Requisição enviada ao gateway; resposta ainda não recebida. |
| `authorized` | Gateway autorizou o valor; captura pendente. |
| `captured` | Valor capturado; transação financeira concluída. |
| `failed` | Gateway recusou o pagamento (saldo insuficiente, dados inválidos, etc.). |
| `cancelled` | Payment cancelado antes da captura, por iniciativa do Buyer ou por expiração do Checkout. |
| `refunded` | Valor estornado após captura, total ou parcialmente. |
| `chargeback` | Disputa aberta pelo Buyer junto à operadora. |

---

## Transições

```
pending ─────────────────► processing
processing ──────────────► authorized
processing ──────────────► failed
authorized ──────────────► captured
authorized ──────────────► cancelled      (cancelamento antes da captura)
captured ────────────────► refunded
captured ────────────────► chargeback
failed ──────────────────► pending        (nova tentativa, se política permitir)
cancelled ───────────────► (terminal)
refunded ────────────────► (terminal)
chargeback ──────────────► (terminal)
```

---

## Regras e Invariantes

- Um `Checkout` possui no máximo um `Payment` ativo por vez. Novas tentativas criam um novo `Payment` apenas após o anterior estar em `failed` ou `cancelled`.
- A transição `authorized → captured` pode ser imediata (captura automática) ou manual, dependendo da configuração do gateway.
- A transição para `refunded` exige que o `Payment` esteja em `captured` e que a `Order` associada esteja em `cancelled` ou `delivered`.
- Um `Payment` em `chargeback` congela operações sobre a `Order` até resolução externa.
- A transição `failed → pending` só é permitida se o `Checkout` ainda não tiver expirado.

---

## Eventos de Domínio Emitidos

| Transição | Evento |
|---|---|
| `→ captured` | `PaymentConfirmed` |
| `→ failed` | `PaymentFailed` |
| `→ cancelled` | `PaymentCancelled` |
| `→ refunded` | `PaymentRefunded` |
| `→ chargeback` | `PaymentChargebacked` |

---

## Referências

- ADR-006 — Checkout inicia a reserva de Inventory
- State Machine: Order
- State Machine: InventoryReservation
