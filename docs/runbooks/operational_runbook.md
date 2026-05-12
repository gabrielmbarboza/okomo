# 8. Operational Runbook

## 8.1. Falha no Pagamento
1. Validar status no gateway externo.
2. Se aprovado lá e pendente no Okomo: `bin/rails payments:sync_status[order_id]`.

## 8.2. Estoque Inconsistente
1. Rodar query de auditoria para comparar `reserved` vs `available`.
2. Executar `Inventory::ReconciliationService.call(variant_id)` para corrigir o drift.

## 8.3. Job Sidekiq Travado
1. Identificar JID na aba "Busy" do painel Sidekiq.
2. Verificar timeouts de APIs externas.
3. Restart seguro dos workers se necessário.

## 8.4. Rollback de Deploy
1. Reverter versão no CI/CD.
2. Validar se a migration é reversível antes do rollback de DB.
3. Limpar cache: `Rails.cache.clear`.