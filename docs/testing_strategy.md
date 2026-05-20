# 9. Testing Strategy (docs/testing_strategy.md)

## 1. Camadas
- **Unitários:** RSpec para lógica de Domain Services e Models.
- **Integração:** Validação de transações no Postgres e comunicação entre módulos.
- **Contrato:** Estabilidade das interfaces entre Bounded Contexts.
- **E2E:** Capybara para fluxos críticos (Checkout).

## 2. Foco Transacional
- Testes de **concorrência** para o Inventory (Locks).
- Testes de **idempotência** para Active Job jobs, independentes do backend de fila.
- Uso de **VCR** para mocks de gateways externos.

## 3. Background Jobs
- Testes unitários devem validar contratos de jobs e handlers sem depender de Solid Queue.
- O ambiente de teste deve usar o adapter `:test` do Active Job por padrão.
- Execução inline pode ser usada pontualmente quando o comportamento do job fizer parte do caso de uso testado.
- Testes de integração com Solid Queue devem ser explícitos e focados na configuração de infraestrutura.
- O domínio não deve instanciar nem referenciar Solid Queue, Sidekiq ou Redis diretamente.

## 4. Métricas
- Cobertura mínima de 90% nos diretórios `app/models` e `app/services`.
- Execução obrigatória no pipeline de CI.
