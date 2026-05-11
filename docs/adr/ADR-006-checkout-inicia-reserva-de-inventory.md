# ADR-006: Checkout Inicia a Reserva de Inventory

## Status
Aceito

## Contexto
Itens adicionados ao Cart representam apenas intenção de compra e podem ser abandonados.

## Decisão
A reserva de Inventory será iniciada somente quando o Buyer começar o Checkout.

## Consequências
### Positivas
- Redução de bloqueio desnecessário de estoque
- Melhor equilíbrio entre experiência do usuário e consistência

### Negativas
- Exige mecanismo de expiração de reservas
