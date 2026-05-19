# Business Rules — Shipping

> Contexto responsavel por calculo de frete, shipments, rastreio e ciclo de entrega.

## Regras de Frete

| ID | Regra |
| --- | --- |
| BR-SHP-001 | Checkout so pode confirmar pedido com endereco de entrega valido e coberto. |
| BR-SHP-002 | Frete deve considerar endereco, itens, dimensoes, peso, seller e metodo de entrega quando aplicavel. |
| BR-SHP-003 | Frete gratis deve ser aplicado somente quando as regras comerciais vigentes forem satisfeitas. |
| BR-SHP-004 | Alteracao de endereco ou itens antes do pagamento exige novo calculo de frete. |

## Regras de Shipment

| ID | Regra |
| --- | --- |
| BR-SHP-005 | Shipment deve ser criado apos estoque comprometido para order paga. |
| BR-SHP-006 | Order com multiplos sellers pode gerar multiplos shipments. |
| BR-SHP-007 | Shipment novo deve iniciar em `pending`. |
| BR-SHP-008 | Transicao para `shipped` exige `tracking_code` e `carrier`. |
| BR-SHP-009 | Estados `delivered`, `returned` e `cancelled` sao terminais. |
| BR-SHP-010 | Shipment cancelado pode provocar cancelamento da order conforme estado da order e politica de compensacao. |
| BR-SHP-011 | Falha de entrega pode voltar para `in_transit` quando houver nova tentativa. |
| BR-SHP-012 | Entrega retornada ao seller deve iniciar processo operacional de suporte, refund ou reenvio conforme politica futura. |

## Regras de Acesso e Rastreio

| ID | Regra |
| --- | --- |
| BR-SHP-013 | Apenas buyer dono do pedido, seller responsavel, admin ou processo autorizado pode acessar rastreio privado. |
| BR-SHP-014 | Atualizacoes de transportadora devem ser idempotentes. |
| BR-SHP-015 | Historico de rastreio deve ser preservado para suporte e auditoria. |

## Eventos Esperados

* `ShipmentDispatched`
* `ShipmentDelivered`
* `ShipmentDeliveryFailed`
* `ShipmentReturned`
* `ShipmentCancelled`
