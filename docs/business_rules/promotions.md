# Business Rules — Promotions

> Contexto responsavel por promocoes, cupons, regras de elegibilidade e descontos.

## Regras de Promocao

| ID | Regra |
| --- | --- |
| BR-PROM-001 | Apenas seller autorizado pode criar promocoes para seus proprios produtos ou loja. |
| BR-PROM-002 | Promocao nova deve iniciar como `draft`. |
| BR-PROM-003 | Promocao ativa exige periodo de vigencia valido. |
| BR-PROM-004 | Data de fim nao pode ser anterior a data de inicio. |
| BR-PROM-005 | Promocao expirada nao pode gerar novos descontos. |
| BR-PROM-006 | Regras de promocao devem ser avaliadas de forma deterministica. |

## Regras de Cupom

| ID | Regra |
| --- | --- |
| BR-PROM-007 | Codigo de cupom deve ser globalmente unico. |
| BR-PROM-008 | Cupons nao podem ser gerados para promocao expirada. |
| BR-PROM-009 | Cupons devem respeitar limite de quantidade por promocao. |
| BR-PROM-010 | Cupom usado nao pode ser reaplicado. |
| BR-PROM-011 | Cupom expirado deve ser considerado invalido, mesmo que ainda esteja marcado como disponivel. |
| BR-PROM-012 | Validacao de cupom deve ser idempotente e nao consumir o cupom. |
| BR-PROM-013 | Aplicacao de cupom deve ser atomica com o checkout/order para evitar duplo uso. |

## Regras de Desconto

| ID | Regra |
| --- | --- |
| BR-PROM-014 | Apenas um cupom pode ser aplicado por pedido. |
| BR-PROM-015 | Cupons nao sao cumulativos no MVP. |
| BR-PROM-016 | Desconto nao pode tornar o total do pedido negativo. |
| BR-PROM-017 | Desconto deve preservar rastreabilidade da promocao, cupom e regra que o originou. |
| BR-PROM-018 | Relatorios devem usar dados agregados quando possivel para reduzir exposicao de dados pessoais. |

## Eventos Esperados

* `PromotionCreated`
* `PromotionActivated`
* `PromotionExpired`
* `CouponGenerated`
* `CouponApplied`
