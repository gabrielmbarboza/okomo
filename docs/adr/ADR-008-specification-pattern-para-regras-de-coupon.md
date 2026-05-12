# ADR-008: Specification Pattern para Regras de Coupon

## Status
Aceito

## Contexto
O contexto Promotions precisa suportar combinações arbitrárias de regras de elegibilidade para um Coupon: faixa de datas, valor mínimo de pedido, quantidade mínima de itens, categoria de produto, Variant específica, primeira compra do Buyer e frete grátis.

Uma implementação inline na model Coupon cresceria de forma descontrolada a cada nova regra, tornando testes unitários inviáveis e violando o princípio de responsabilidade única. Além disso, as regras precisam ser revalidadas sempre que o conteúdo do pedido mudar durante o Checkout.

## Decisão
Encapsular cada regra de elegibilidade em um objeto de especificação independente, com interface uniforme de avaliação. As especificações serão compostas por um CouponValidator que as avalia contra um CouponApplicationContext imutável, construído a partir dos dados do Buyer, dos itens do pedido e dos totais calculados. Um SpecificationFactory será responsável por instanciar as specs ativas a partir dos atributos persistidos no Coupon.

## Consequências
### Positivas
- Cada regra é testável de forma isolada, sem dependências externas
- Adicionar uma nova regra não altera classes existentes (Open/Closed Principle)
- O CouponApplicationContext explicita exatamente quais dados uma regra pode inspecionar
- Revalidação ao mudar o pedido é trivial: reconstruir o contexto e reexecutar o validator

### Negativas
- Mais arquivos e indireção em comparação com lógica inline
- O SpecificationFactory precisa ser atualizado a cada nova especificação criada
- Curva de aprendizado para desenvolvedores não familiarizados com o padrão
