# ADR-002: PostgreSQL como Banco de Dados Principal

## Status
Aceito

## Contexto
O sistema exige consistência transacional, constraints robustas e suporte a concorrência.

## Decisão
Utilizar PostgreSQL como banco de dados principal.

## Consequências
### Positivas
- ACID completo
- Excelente suporte a locking e índices
- Recursos avançados como JSONB e partial indexes

### Negativas
- Maior complexidade operacional em comparação com soluções embarcadas
