# ADR-011: Estratégia de Testes por Camada

## Status
Aceito

## Contexto
O Okomo possui lógica de domínio complexa (especificações de Coupon, locking de Inventory, fluxo transacional do Checkout) distribuída em múltiplas camadas: domain objects, service objects, controllers e jobs. Sem uma estratégia clara, há risco de testes lentos por excesso de testes de integração, cobertura fraca por excesso de testes unitários sem contrato, e duplicação de esforço entre camadas.

## Decisão
Adotar uma pirâmide de testes com três camadas explícitas. A base serão testes unitários para domain objects, Specifications e value objects, sempre sem tocar banco de dados ou rede. O meio serão testes de integração para service objects e jobs, usando banco real em transações revertidas ao final de cada teste. O topo serão testes de sistema (request specs) cobrindo apenas os fluxos críticos de ponta a ponta: reserva e liberação de Inventory, fluxo completo de Checkout e aplicação de Coupon. Factories serão usadas via FactoryBot; fixtures serão evitadas.

## Consequências
### Positivas
- Testes unitários de domain objects executam em milissegundos, sem dependência de infraestrutura
- A separação de camadas torna explícito o que cada teste valida e qual o custo de executá-lo
- Fluxos críticos têm cobertura de ponta a ponta sem duplicar testes de unidade
- A pirâmide guia onde escrever o próximo teste ao adicionar uma feature

### Negativas
- Disciplina necessária para não escrever testes de integração onde um unitário bastaria
- FactoryBot com associações profundas pode tornar testes lentos se não for gerenciado
- Testes de sistema dependem de banco real e aumentam o tempo total da suíte em CI
