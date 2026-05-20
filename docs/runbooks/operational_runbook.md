# 8. Operational Runbook

## 8.1. Falha no Pagamento
1. Validar status no gateway externo.
2. Se aprovado lá e pendente no Okomo: `bin/rails payments:sync_status[order_id]`.

## 8.2. Estoque Inconsistente
1. Rodar query de auditoria para comparar `reserved` vs `available`.
2. Executar `Inventory::ReconciliationService.call(variant_id)` para corrigir o drift.

## 8.3. Job Solid Queue Travado ou com Falha
1. Identificar a fila afetada (`default`, `mailers`, `events` ou `maintenance`) e verificar logs do processo `bin/jobs`.
2. Consultar as tabelas do Solid Queue para localizar jobs bloqueados, falhos ou com muitas tentativas.
3. Verificar timeouts de APIs externas, locks no PostgreSQL e saturação do pool de conexões.
4. Reiniciar workers Solid Queue de forma graciosa se houver processo preso.
5. Reprocessar jobs somente quando a operação for idempotente ou quando houver confirmação do responsável pelo domínio.

## 8.4. Rollback de Deploy
1. Reverter versão no CI/CD.
2. Validar se a migration é reversível antes do rollback de DB.
3. Limpar cache: `Rails.cache.clear`.
