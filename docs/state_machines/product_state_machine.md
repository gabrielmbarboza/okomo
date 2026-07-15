# State Machine — Product

## Visão Geral

Este documento descreve a máquina de estados do agregado `Product` no Bounded Context Catalog.

O `Product` representa um produto conceitual cadastrado por um seller. Seu ciclo de publicação é independente do ciclo de vida de suas `Variant`s (ver nota ao final).

---

## Estados

### 1. draft

**Descrição:** Estado inicial de todo produto novo (BR-CAT-002).

**Características:**

- Produto ainda não está pronto para venda pública
- Não aparece no catálogo público (BR-CAT-003)
- Pode ser editado livremente pelo seller

**Transições Saem De:**

- Nenhuma (estado inicial)

**Transições Vão Para:**

- `published` (via `Publish Product`)

---

### 2. published

**Descrição:** Produto publicado e visível no catálogo.

**Características:**

- Passou pelas validações de publicação (BR-CAT-004)
- Visível para Buyers, sujeito às regras de busca/exibição (fora de escopo desta fase — BR-CAT-003/005/006/015/016/018)

**Transições Saem De:**

- `draft` (via `Publish Product`)

**Transições Vão Para:**

- `archived` (fora do escopo desta fase — nenhum caso de uso implementado ainda)

---

### 3. archived

**Descrição:** Produto fora de circulação, reservado para evolução futura.

**Características:**

- Nenhum caso de uso desta fase transiciona um Product para `archived`
- Estado reservado no `VALID_STATUSES` do agregado para compatibilidade futura

**Transições Saem De:**

- Nenhuma nesta fase

**Transições Vão Para:**

- Nenhuma nesta fase

---

## Transições de Estado

### draft → published

**Acionador:** Seller publica o produto
**Caso de Uso:** Publish Product
**Efeitos Colaterais:**

- `updated_at` atualizado
- Evento `ProductPublished` publicado

**Guard Conditions:**

- Entidade (`Product#publish!`, auto-contido): produto deve estar `draft`; produto deve ter `description` presente
- Service (`Catalog::Services::PublishProduct`, cross-aggregate): produto deve ter ao menos uma `Variant` com `sellable?` verdadeiro (BR-CAT-004) — consulta feita via `variant_repository.find_by_product_id`, não pode ser verificada pela entidade isoladamente

---

### Transições Fora do Fluxo desta Fase

`published → archived` não possui caso de uso implementado nesta fase. O valor `archived` existe em `VALID_STATUSES` apenas para compatibilidade futura (ex.: uma futura `ArchiveProduct`). Introduzir essa transição exige nova decisão e evento de domínio explícito.

---

## Nota sobre Variant

`Variant.status` também assume `draft`/`published`/`archived` (ver `docs/data_model/overview.md`), mas não possui service de transição dedicado nesta fase — nenhuma `PublishVariant` ou equivalente é implementada. `Variant#sellable?` é calculado (`!archived?`) e usado apenas como guard condition dentro de `PublishProduct`, não como uma máquina de estados própria com transições publicadas.

---

## Validações e Invariantes

1. Todo produto novo inicia em `draft` (BR-CAT-002).
2. Produto `draft` nunca aparece no catálogo público (BR-CAT-003).
3. Publicação exige dados obrigatórios, ao menos uma variante vendável e descrição suficiente (BR-CAT-004).
4. Nesta fase, `Product` é um PORO puro — persistência e transações pertencem a uma fase futura.
