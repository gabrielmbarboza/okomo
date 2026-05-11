# ADR-005: Estratégia de Snapshot para OrderItem

## Status
Aceito

## Contexto
O preço e o nome de uma Variant podem mudar após a compra.

## Decisão
Persistir em OrderItem um snapshot contendo:
- `variant_id`
- `variant_name`
- `unit_price`
- `quantity`
- `subtotal`

## Consequências
### Positivas
- Preservação histórica
- Auditoria financeira

### Negativas
- Redundância intencional de dados
