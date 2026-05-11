# ADR-007: Variant é Responsável por Pricing e Inventory

## Status
Aceito

## Contexto
Um Product representa um conceito genérico, enquanto cada Variant possui características comerciais próprias.

## Decisão
Preço e estoque serão definidos na entidade Variant, e não em Product.

## Consequências
### Positivas
- Modelagem mais realista
- Flexibilidade comercial

### Negativas
- Maior número de entidades e relacionamentos
