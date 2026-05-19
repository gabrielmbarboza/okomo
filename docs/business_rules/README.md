# Business Rules — Okomo

> Status: Draft
> Responsavel: Engenharia de Software
> Ultima atualizacao: 2026-05-19

Este diretorio consolida as regras de negocio do Okomo. Ele complementa os
casos de uso, maquinas de estado, ADRs e modelo de dominio, servindo como
fonte rapida para implementacao, testes e revisao de produto.

## Como Usar

Cada regra possui um identificador estavel no formato `BR-<CONTEXTO>-<NUMERO>`.
Use esses IDs em specs, comentarios de PR, ADRs e discussoes de produto quando
uma decisao depender de uma regra explicita.

Regras de negocio devem ser atualizadas quando:

* um caso de uso muda comportamento observavel;
* uma maquina de estado ganha ou perde transicoes;
* uma politica comercial, financeira, operacional ou de privacidade muda;
* uma nova entidade de dominio introduz invariantes relevantes.

## Contextos Documentados

| Contexto | Documento |
| --- | --- |
| Identity e Access Management | [identity.md](identity.md) |
| Catalog | [catalog.md](catalog.md) |
| Inventory | [inventory.md](inventory.md) |
| Orders | [orders.md](orders.md) |
| Checkout | [checkout.md](checkout.md) |
| Promotions | [promotions.md](promotions.md) |
| Payments | [payments.md](payments.md) |
| Shipping | [shipping.md](shipping.md) |
| Privacy e LGPD | [privacy.md](privacy.md) |

## Escopo das Regras

Regras de negocio descrevem comportamento do produto e invariantes do dominio.
Elas nao devem documentar detalhes acidentais de implementacao, como nomes de
classes, estrutura de controllers ou estrategia de persistencia, exceto quando
esses detalhes forem uma decisao arquitetural que protege a regra.

## Relacao com Outros Documentos

* Casos de uso descrevem fluxos.
* Maquinas de estado descrevem ciclos de vida e transicoes.
* ADRs registram decisoes arquiteturais e trade-offs.
* Business rules registram invariantes, politicas e restricoes de dominio.

## Checklist de PR

Ao implementar ou alterar comportamento de dominio:

* [ ] a regra afetada esta documentada ou atualizada aqui;
* [ ] specs cobrem o caminho feliz e violacoes da regra;
* [ ] eventos de dominio relevantes continuam consistentes;
* [ ] impactos em LGPD, auditoria e seguranca foram avaliados;
* [ ] regras duplicadas nos casos de uso foram reconciliadas.
