# ADR-020: Infraestrutura Declarativa para Entidades de Domínio

- **Status:** Accepted
- **Data:** 2026-05-17
- **Contexto:** Shared Kernel
- **Relacionado:** ADR-001 (Monólito Modular), ADR-011 (Estratégia de Testes por Camada), ADR-015 (Custom Rails Generators)

---

## Contexto

As entidades de domínio do Okomo são POROs organizados por bounded context.
À medida que novos domínios são modelados, várias entidades passam a repetir
o mesmo tipo de código: declaração de atributos, `initialize`, defaults e
validações simples.

Essa repetição reduz legibilidade e desloca a atenção das regras de negócio
para infraestrutura básica de objetos.

---

## Decisão

- Todas as entidades de domínio herdarão de `Shared::Entities::BaseEntity`.
- Atributos serão declarados com `attributes`.
- Valores padrão poderão ser definidos com `attribute`.
- O `initialize` será fornecido automaticamente.
- Validações serão declaradas com `validates`.
- O método `validate!` executará as regras configuradas.
- A infraestrutura permanecerá independente de ActiveModel e ActiveRecord.

---

## Benefícios

- Redução significativa de código repetitivo.
- Experiência semelhante ao Rails.
- Entidades mais legíveis.
- Consistência entre bounded contexts.
- Maior foco nas regras de negócio.

---

## Consequências

Entidades passam a declarar estrutura e validações de forma explícita:

```ruby
class Role < Shared::Entities::BaseEntity
  attribute :id, default: -> { SecureRandom.uuid }
  attribute :name
  attribute :created_at, default: -> { Time.current }

  validates :id, presence: true
  validates :name, presence: true
end
```

O `BaseEntity` continua sendo uma infraestrutura leve e framework-agnostic.
Regras de negócio específicas permanecem nas entidades concretas, enquanto
validações estruturais comuns ficam centralizadas na base.
