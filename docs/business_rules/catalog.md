# Business Rules — Catalog

> Contexto responsavel por produtos, variantes, precificacao exibida e publicacao no catalogo.

## Regras de Produto

| ID | Regra |
| --- | --- |
| BR-CAT-001 | Apenas sellers aprovados e ativos podem criar produtos. |
| BR-CAT-002 | Todo produto novo deve iniciar como `draft`. |
| BR-CAT-003 | Produto `draft` nao deve aparecer no catalogo publico. |
| BR-CAT-004 | Produto so pode ser publicado quando possuir dados obrigatorios, ao menos uma variante vendavel e imagens ou descricao suficientes para compra informada. |
| BR-CAT-005 | Produto de seller suspenso deve ser removido da exibicao publica ou marcado como indisponivel para novas vendas. |
| BR-CAT-006 | Produto inativo, arquivado ou sem condicao de venda nao deve aparecer em busca publica como item compravel. |
| BR-CAT-007 | Cada produto pertence a um unico seller. |
| BR-CAT-008 | Sellers so podem editar produtos sob sua propria titularidade. |

## Regras de Variante

| ID | Regra |
| --- | --- |
| BR-CAT-009 | Uma variante representa a unidade vendavel do catalogo. |
| BR-CAT-010 | SKU deve ser unico dentro do escopo definido para o produto e rastreavel em pedidos, estoque e suporte. |
| BR-CAT-011 | Preco de variante deve ser maior que zero. |
| BR-CAT-012 | Dimensoes e peso, quando informados, devem ser positivos e coerentes para calculo de frete. |
| BR-CAT-013 | Variante sem estoque disponivel pode ser exibida, mas nao pode ser adicionada ao checkout como item vendavel. |
| BR-CAT-014 | Mudancas de preco nao alteram pedidos ou order items ja criados. |

## Regras de Busca e Exibicao

| ID | Regra |
| --- | --- |
| BR-CAT-015 | Busca publica deve retornar apenas produtos publicados e pertencentes a sellers aptos a vender. |
| BR-CAT-016 | Produtos sem estoque devem ser claramente indicados como indisponiveis. |
| BR-CAT-017 | Precos exibidos devem refletir a variante selecionada e as promocoes aplicaveis quando houver contexto suficiente. |
| BR-CAT-018 | Informacoes publicas nao devem expor dados pessoais ou comerciais sensiveis do seller. |

## Eventos Esperados

* `ProductCreated` (Fase 3)
* `ProductPublished` (Fase 3)
* `VariantCreated` (Fase 3)

Ver `docs/domain_events.md` para a lista completa, incluindo eventos futuros fora do escopo desta fase.
