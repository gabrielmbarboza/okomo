# ADR-003: UUID como Chaves Primárias

## Status
Aceito

## Contexto
O sistema poderá evoluir para multi-tenant e integrações externas.

## Decisão
Todas as entidades persistidas utilizarão UUID como chave primária.

## Consequências
### Positivas
- Identificadores não previsíveis
- Facilidade de integração
- Melhor suporte a distribuição

### Negativas
- Índices maiores
- Menor legibilidade em consultas manuais
