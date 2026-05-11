# ADR-004: Pessimistic Locking para Inventory

## Status
Aceito

## Contexto
Durante o Checkout, múltiplos Buyers podem tentar reservar a mesma Variant simultaneamente.

## Decisão
Utilizar Pessimistic Locking (`SELECT ... FOR UPDATE`) ao reservar ou liberar Inventory.

## Consequências
### Positivas
- Prevenção de overselling
- Consistência forte

### Negativas
- Possível aumento de contenção em alta concorrência
