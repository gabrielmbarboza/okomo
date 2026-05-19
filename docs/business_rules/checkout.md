# Business Rules — Checkout

> Contexto orquestrador da finalizacao de compra, integrando catalogo, inventory, promotions, shipping, payments e orders.

## Regras de Inicio

| ID | Regra |
| --- | --- |
| BR-CHK-001 | Checkout exige buyer autenticado. |
| BR-CHK-002 | Checkout exige carrinho com ao menos um item vendavel. |
| BR-CHK-003 | Checkout exige endereco de entrega valido antes da confirmacao final. |
| BR-CHK-004 | Criacao de checkout deve validar disponibilidade dos itens e iniciar reservas de estoque. |
| BR-CHK-005 | Checkout deve possuir expiracao; politica inicial e 15 minutos. |
| BR-CHK-006 | Checkout expirado deve liberar reservas pendentes e impedir novas tentativas de pagamento. |

## Regras de Totais

| ID | Regra |
| --- | --- |
| BR-CHK-007 | Totais devem considerar itens, descontos, frete e valores financeiros obrigatorios. |
| BR-CHK-008 | Totais exibidos ao buyer devem ser consistentes com os snapshots que serao usados na order. |
| BR-CHK-009 | Alteracao de endereco, frete, cupom ou itens deve recalcular os totais antes do pagamento. |
| BR-CHK-010 | Checkout nao pode confirmar pedido com total negativo. |

## Regras de Cupom e Frete

| ID | Regra |
| --- | --- |
| BR-CHK-011 | Apenas um cupom pode ser aplicado por checkout/pedido. |
| BR-CHK-012 | Cupom deve ser validado pelo contexto Promotions antes de impactar total. |
| BR-CHK-013 | Frete deve ser recalculado quando endereco ou itens relevantes mudarem. |
| BR-CHK-014 | Endereco fora da area atendida deve impedir a confirmacao do checkout. |

## Regras de Pagamento e Compensacao

| ID | Regra |
| --- | --- |
| BR-CHK-015 | Checkout deve ter no maximo um payment ativo por vez. |
| BR-CHK-016 | Nova tentativa de pagamento so pode ocorrer quando a tentativa anterior estiver `failed` ou `cancelled` e o checkout ainda nao tiver expirado. |
| BR-CHK-017 | Falha de pagamento deve manter o checkout recuperavel enquanto nao expirado e liberar recursos quando aplicavel. |
| BR-CHK-018 | Confirmacao de pagamento deve confirmar reservas e confirmar/criar a order de forma consistente. |
| BR-CHK-019 | Operacoes criticas do checkout devem ser idempotentes. |
| BR-CHK-020 | Notificacoes de confirmacao devem ser idempotentes. |

## Eventos Esperados

* `CheckoutStarted`
* `CouponApplied`
* `PaymentProcessed`
* `OrderConfirmed`
* `InventoryReserved`
