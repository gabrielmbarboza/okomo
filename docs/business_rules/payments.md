# Business Rules — Payments

> Contexto responsavel por tentativas de pagamento, autorizacao, captura, falhas, reembolso e chargeback.

## Regras de Tentativa

| ID | Regra |
| --- | --- |
| BR-PAY-001 | Um checkout pode possuir no maximo um payment ativo por vez. |
| BR-PAY-002 | Nova tentativa deve criar novo payment apenas quando o anterior estiver `failed` ou `cancelled`. |
| BR-PAY-003 | Payment deve iniciar em `pending`. |
| BR-PAY-004 | Requisicoes ao gateway devem ser idempotentes por chave de operacao. |
| BR-PAY-005 | Dados sensiveis de pagamento nao devem ser armazenados no Okomo fora de tokens ou referencias seguras do gateway. |

## Regras de Estado

| ID | Regra |
| --- | --- |
| BR-PAY-006 | `authorized` indica autorizacao do gateway, mas nao captura financeira concluida. |
| BR-PAY-007 | `captured` indica pagamento confirmado e deve emitir `PaymentConfirmed`. |
| BR-PAY-008 | `failed` permite nova tentativa somente se o checkout ainda nao tiver expirado. |
| BR-PAY-009 | `cancelled`, `refunded` e `chargeback` sao estados terminais. |
| BR-PAY-010 | Captura pode ser imediata ou manual conforme configuracao do gateway. |
| BR-PAY-011 | Chargeback deve congelar operacoes da order ate resolucao externa. |

## Regras de Reembolso

| ID | Regra |
| --- | --- |
| BR-PAY-012 | Refund exige payment em `captured`. |
| BR-PAY-013 | Refund exige order associada em estado compativel, como `cancelled` ou `delivered`. |
| BR-PAY-014 | Refund deve ser rastreavel por referencia do gateway, valor, motivo e responsavel. |
| BR-PAY-015 | Eventos de webhook do gateway devem ser processados de forma idempotente. |

## Eventos Esperados

* `PaymentConfirmed`
* `PaymentFailed`
* `PaymentCancelled`
* `PaymentRefunded`
* `PaymentChargebacked`
