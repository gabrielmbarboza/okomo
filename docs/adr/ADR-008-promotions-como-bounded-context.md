# ADR-008 — Promotions como Bounded Context e Coupon como Entidade
- **Status:** Aceito
- **Data:** 2026-05-12

---

## Contexto
Inicialmente, `Coupon` foi considerado como um domínio independente. Entretanto, ao aprofundar a modelagem do negócio, observou-se que o conceito central é a **promoção comercial**, enquanto o `Coupon` é apenas um mecanismo opcional para ativar uma promoção.

O sistema deverá suportar diferentes estratégias promocionais, incluindo:
- promoções automáticas;
- promoções ativadas por código;
- campanhas sazonais;
- regras de elegibilidade;
- descontos percentuais;
- descontos de valor fixo;
- frete grátis;
- promoções para primeira compra.

Exemplos de negócio:
- 10% de desconto na primeira compra;
- Frete grátis acima de R$ 200,00;
- Black Friday;
- Cupom `WELCOME10`;
- Compre 3 e pague 2.

---

## Decisão
O Okomo adotará um Bounded Context denominado `Promotions`, responsável por toda a lógica de descontos e campanhas promocionais.

Dentro desse contexto existirão, inicialmente, as seguintes entidades:
- `Promotion`
- `Coupon`
- `PromotionRule`
- `Discount`

O `Coupon` será uma entidade opcional associada a uma `Promotion` e funcionará como um mecanismo de ativação da promoção.

Promoções poderão ser:

1. Automáticas (sem código);
2. Ativadas por `Coupon`;
3. Baseadas em regras específicas;
4. Limitadas por período, quantidade de usos ou elegibilidade do cliente.

---

## Estrutura Conceitual
```text
Promotion
 ├── has_one Coupon (optional)
 ├── has_many PromotionRule
 └── generates Discount