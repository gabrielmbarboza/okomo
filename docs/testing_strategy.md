# 9. Testing Strategy (docs/testing_strategy.md)

## 1. Camadas
- **Unitários:** RSpec para lógica de Domain Services e Models.
- **Integração:** Validação de transações no Postgres e comunicação entre módulos.
- **Contrato:** Estabilidade das interfaces entre Bounded Contexts.
- **E2E:** Capybara para fluxos críticos (Checkout).

## 2. Foco Transacional
- Testes de **concorrência** para o Inventory (Locks).
- Testes de **idempotência** para Sidekiq Jobs.
- Uso de **VCR** para mocks de gateways externos.

## 3. Métricas
- Cobertura mínima de 90% nos diretórios `app/models` e `app/services`.
- Execução obrigatória no pipeline de CI.