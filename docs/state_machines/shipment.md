# State Machine: Shipment

## Visão Geral

Representa o ciclo de vida de uma entrega associada a uma `Order` paga. O `Shipment` é criado automaticamente após o evento `InventoryCommitted`, e seu estado avança conforme o Seller processa e despacha o pedido e conforme atualizações de rastreio são recebidas.

---

## Estados

| Estado | Descrição |
|---|---|
| `pending` | Shipment criado; aguardando ação do Seller para preparar o envio. |
| `preparing` | Seller iniciou a separação e embalagem dos itens. |
| `ready_to_ship` | Pacote pronto; aguardando coleta pela transportadora. |
| `shipped` | Pacote despachado; código de rastreio disponível. |
| `in_transit` | Em trânsito conforme atualização da transportadora. |
| `out_for_delivery` | Saiu para entrega no dia. |
| `delivered` | Entrega confirmada. |
| `failed_delivery` | Tentativa de entrega malsucedida (destinatário ausente, endereço incorreto, etc.). |
| `returned` | Pacote retornou ao Seller após falha definitiva de entrega. |
| `cancelled` | Shipment cancelado antes do despacho. |

---

## Transições

```
(InventoryCommitted) ────► pending
pending ─────────────────► preparing
pending ─────────────────► cancelled
preparing ───────────────► ready_to_ship
preparing ───────────────► cancelled
ready_to_ship ───────────► shipped
shipped ─────────────────► in_transit
in_transit ──────────────► out_for_delivery
in_transit ──────────────► failed_delivery
out_for_delivery ────────► delivered
out_for_delivery ────────► failed_delivery
failed_delivery ─────────► in_transit          (nova tentativa de entrega)
failed_delivery ─────────► returned            (esgotadas as tentativas)
```

---

## Regras e Invariantes

- Um `Shipment` é criado sempre que um evento `InventoryCommitted` é emitido para a `Order` associada. Uma `Order` com múltiplos Sellers pode gerar múltiplos `Shipments`.
- A transição `→ shipped` exige que um código de rastreio (`tracking_code`) e uma transportadora (`carrier`) estejam preenchidos.
- As transições a partir de `shipped`, `in_transit`, `out_for_delivery` e `failed_delivery` podem ser disparadas automaticamente por webhooks da transportadora ou manualmente pelo Seller.
- Os estados `delivered`, `returned` e `cancelled` são terminais; nenhuma transição é permitida a partir deles.
- A transição `→ cancelled` aciona o evento `ShipmentCancelled`, que pode provocar a transição da `Order` para `cancelled` dependendo do seu estado.

---

## Eventos de Domínio Emitidos

| Transição | Evento |
|---|---|
| `→ shipped` | `ShipmentDispatched` |
| `→ delivered` | `ShipmentDelivered` |
| `→ failed_delivery` | `ShipmentDeliveryFailed` |
| `→ returned` | `ShipmentReturned` |
| `→ cancelled` | `ShipmentCancelled` |

---

## Referências

- State Machine: Order
- State Machine: InventoryReservation
- ADR-006 — Checkout inicia a reserva de Inventory
