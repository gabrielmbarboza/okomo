# Business Rules — Orders

> Contexto responsavel por pedidos, order items, snapshots financeiros e ciclo transacional apos checkout.

## Regras de Criacao

| ID | Regra |
| --- | --- |
| BR-ORD-001 | Apenas buyer autenticado pode criar pedido. |
| BR-ORD-002 | Pedido exige ao menos um item valido. |
| BR-ORD-003 | Pedido deve ser criado com identificador unico. |
| BR-ORD-004 | Order items devem armazenar snapshots de produto, variante, preco, desconto e informacoes necessarias para historico. |
| BR-ORD-005 | Mudancas futuras no catalogo ou em promocoes nao podem alterar snapshots de pedidos existentes. |
| BR-ORD-006 | Totais do pedido devem ser recalculados sempre que itens, descontos ou frete mudarem antes da confirmacao. |

## Regras de Modificacao

| ID | Regra |
| --- | --- |
| BR-ORD-007 | Pedido so pode ser modificado enquanto estiver em estado editavel, como `draft` ou `pending_payment`. |
| BR-ORD-008 | Pedido pago nao pode receber adicao ou remocao comum de itens. |
| BR-ORD-009 | Quantidade de item deve ser positiva. |
| BR-ORD-010 | Remocao de item antes do pagamento deve liberar ou ajustar reservas de estoque correspondentes. |
| BR-ORD-011 | Toda alteracao relevante no pedido deve manter historico auditavel. |

## Regras de Estado

| ID | Regra |
| --- | --- |
| BR-ORD-012 | `Order` so avanca para `paid` apos `PaymentConfirmed`. |
| BR-ORD-013 | `paid` significa que pagamento foi confirmado e estoque foi comprometido. |
| BR-ORD-014 | A transicao `paid -> processing` e responsabilidade do seller. |
| BR-ORD-015 | Cancelamento a partir de `paid` exige que nenhum shipment esteja em transito. |
| BR-ORD-016 | Estados `delivered`, `cancelled` e `refunded` sao terminais. |
| BR-ORD-017 | Pedido cobrado e posteriormente cancelado deve iniciar fluxo de refund. |
| BR-ORD-018 | Apenas o dono do pedido ou usuario autorizado pode consultar rastreamento e detalhes privados. |

## Eventos Esperados

* `OrderCreated`
* `OrderItemAdded`
* `OrderItemRemoved`
* `OrderPaid`
* `OrderCancelled`
* `OrderRefunded`
* `OrderShipped`
* `OrderDelivered`
