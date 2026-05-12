# ADR-010: Namespacing de Rotas por Bounded Context

## Status
Aceito

## Contexto
O Okomo expõe uma API HTTP para clientes externos. Com múltiplos bounded contexts (Catalog, Inventory, Ordering, Checkout, Payment, Shipment, Promotions), é necessário decidir como organizar os endpoints sem criar acoplamento implícito entre contextos nem sobrecarregar os clientes com múltiplas chamadas para dados relacionados.

## Decisão
Cada bounded context terá seu próprio namespace de rotas e controller base, dependendo apenas de suas próprias queries e services. Nenhum controller acessará diretamente models de outro contexto. Para telas que exigem dados compostos de múltiplos contextos, serão criados composite endpoints somente leitura em um namespace dedicado, tratados como adapters de leitura e documentados separadamente. A API será versionada no path (/api/v1/) desde o início.

## Consequências
### Positivas
- O isolamento entre contextos é preservado na camada de controllers
- Composite endpoints explicitam e centralizam os casos de leitura entre fronteiras
- Versionamento desde o início evita breaking changes futuros sem cerimônia
- A estrutura de pastas reflete diretamente a arquitetura de domínio

### Negativas
- Maior número de arquivos e namespaces em comparação com controllers genéricos
- Composite endpoints precisam ser mantidos sincronizados quando o domínio evolui
- Disciplina necessária para não deixar lógica de negócio vazar para os composites
