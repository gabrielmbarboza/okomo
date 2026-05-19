# Business Rules — Inventory

> Contexto responsavel por disponibilidade, reservas, consumo e reconciliacao de estoque.

## Regras de Quantidade

| ID | Regra |
| --- | --- |
| BR-INV-001 | Quantidades de estoque nao podem ser negativas. |
| BR-INV-002 | `available_quantity` representa somente unidades livres para nova reserva. |
| BR-INV-003 | `reserved_quantity` representa unidades reservadas por checkouts ainda nao consumidos nem liberados. |
| BR-INV-004 | A soma operacional de reservas ativas nao pode exceder a disponibilidade no momento de cada reserva. |
| BR-INV-005 | Ajustes manuais devem registrar justificativa e autor. |
| BR-INV-006 | Ajustes negativos podem exigir autorizacao adicional quando ultrapassarem threshold operacional definido. |

## Regras de Reserva

| ID | Regra |
| --- | --- |
| BR-INV-007 | Toda reserva deve estar associada a uma variante, a um checkout e a uma quantidade positiva. |
| BR-INV-008 | Nenhuma reserva pode ser criada se `available_quantity` for menor que a quantidade solicitada. |
| BR-INV-009 | Criacao de reserva deve decrementar `available_quantity` e incrementar `reserved_quantity` atomicamente. |
| BR-INV-010 | Reservas devem ser criadas dentro de transacao com bloqueio pessimista do estoque. |
| BR-INV-011 | Uma reserva em `reserved` pode ir somente para `committed` ou `released`. |
| BR-INV-012 | Reservas `committed` e `released` sao terminais. |
| BR-INV-013 | Commit de reserva deve decrementar `reserved_quantity` sem devolver disponibilidade. |
| BR-INV-014 | Release de reserva deve decrementar `reserved_quantity` e devolver a quantidade a `available_quantity`. |
| BR-INV-015 | Jobs de expiracao de reserva devem ser idempotentes. |

## Regras de Reconciliacao

| ID | Regra |
| --- | --- |
| BR-INV-016 | Reconciliacao deve ser repetivel, auditavel e rastrear diferencas entre estoque fisico e sistema. |
| BR-INV-017 | Discrepancias acima de threshold devem gerar alerta operacional. |
| BR-INV-018 | Falha na liberacao de estoque reservado deve gerar alerta critica. |

## Eventos Esperados

* `InventoryReserved`
* `InventoryCommitted`
* `InventoryReleased`
* `InventoryAdjusted`
* `InventoryReconciled`
