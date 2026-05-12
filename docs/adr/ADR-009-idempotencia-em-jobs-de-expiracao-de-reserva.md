# ADR-009: Idempotência em Jobs de Expiração de Reserva de Inventory

## Status
Aceito

## Contexto
Quando um Checkout expira ou falha, a reserva de estoque precisa ser liberada via background job no Sidekiq. O Sidekiq oferece garantia de execução at-least-once: em caso de crash do worker ou reinicialização do processo, o mesmo job pode ser executado mais de uma vez para o mesmo Checkout.

Uma implementação não-idempotente executando o job duas vezes resultaria em dupla liberação de estoque, corrompendo os contadores de Inventory silenciosamente e criando disponibilidade fantasma.

## Decisão
Introduzir a entidade InventoryReservation para registrar cada reserva com um status explícito (reserved, committed, released). O job de liberação utilizará uma transição de estado atômica via UPDATE com filtro por status, garantindo que apenas a primeira execução produza efeito. Execuções concorrentes do mesmo job utilizarão FOR UPDATE SKIP LOCKED para não bloquear umas às outras. O job será enfileirado com um identificador derivado do Checkout para deduplicação.

## Consequências
### Positivas
- O job pode ser executado N vezes com segurança; apenas a primeira execução altera o estado
- O ciclo de vida completo de cada reserva fica auditável via InventoryReservation
- FOR UPDATE SKIP LOCKED elimina contenção entre workers sem bloquear a fila
- A entidade InventoryReservation habilita relatórios futuros de estoque comprometido

### Negativas
- Adiciona uma tabela e uma entidade ao modelo de domínio do contexto Inventory
- O fluxo de reserva e liberação passa por dois modelos, aumentando a superfície de código
- Requer PostgreSQL 9.5+ para suporte a SKIP LOCKED (sem impacto prático dado o ADR-002)
