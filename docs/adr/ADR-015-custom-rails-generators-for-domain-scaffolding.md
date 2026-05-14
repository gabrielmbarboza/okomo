# ADR-015: Custom Rails Generators for Domain Scaffolding

## Status
Aceito

## Contexto
O Okomo segue princípios de Domain-Driven Design (DDD) com uma arquitetura de monólito modular. A criação manual de bounded contexts e artefatos de domínio (entidades, serviços, value objects, repositories, eventos) envolve trabalho repetitivo e propenso a erros, como:

- Criação manual de estrutura de diretórios para cada bounded context
- Repetição de código boilerplate para entidades, serviços e value objects
- Possibilidade de inconsistência na nomenclatura e estrutura entre bounded contexts
- Tempo gasto em tarefas mecânicas em vez de lógica de negócio

Foram avaliadas alternativas:
- **Manter criação manual**: Simples, mas propenso a erros e inconsistências
- **Usar gems de scaffolding existentes**: Geralmente não seguem convenções específicas do projeto
- **Criar generators customizados**: Flexibilidade total, consistência garantida, redução de trabalho repetitivo

## Decisão
O Okomo adota generators customizados do Rails para automatizar a criação de bounded contexts e artefatos de domínio, garantindo consistência arquitetural e reduzindo trabalho repetitivo.

### Generators Implementados

1. **`rails generate domain <Name>`**
   - Cria estrutura completa de bounded context
   - Gera módulo principal
   - Cria diretórios: entities, services, repositories, value_objects, events, specifications, policies

2. **`rails generate domain_entity <Domain> <Name>`**
   - Gera entidade herdando de `Shared::Entities::BaseEntity`
   - Localização: `app/domains/<domain>/entities/<name>.rb`

3. **`rails generate domain_service <Domain> <Name>`**
   - Gera serviço herdando de `Shared::Services::BaseService`
   - Localização: `app/domains/<domain>/services/<name>.rb`
   - Inclui método `call` com `raise NotImplementedError`

4. **`rails generate domain_value_object <Domain> <Name>`**
   - Gera value object herdando de `Shared::ValueObjects::BaseValueObject`
   - Localização: `app/domains/<domain>/value_objects/<name>.rb`

5. **`rails generate domain_repository <Domain> <Name>`**
   - Gera repository
   - Localização: `app/domains/<domain>/repositories/<name>.rb`

6. **`rails generate domain_event <Domain> <Name>`**
   - Gera domain event com payload e timestamp
   - Localização: `app/domains/<domain>/events/<name>.rb`
   - Inclui `freeze` para imutabilidade

## Consequências

### Positivas
- **Consistência arquitetural**: Todos os bounded contexts seguem a mesma estrutura
- **Redução de trabalho repetitivo**: Menos tempo gasto em boilerplate
- **Menor probabilidade de erros**: Estrutura gerada automaticamente sem erros manuais
- **Padronização**: Nomenclatura e localização consistentes
- **Velocidade de desenvolvimento**: Novos bounded contexts criados rapidamente
- **Documentação viva**: Generators servem como documentação da estrutura esperada
- **Onboarding facilitado**: Novos desenvolvedores podem usar generators para aprender a estrutura

### Negativas
- **Manutenção adicional**: Generators precisam ser mantidos em sincronia com a arquitetura
- **Complexidade inicial**: Curva de aprendizado para entender como os generators funcionam
- **Flexibilidade reduzida**: Estrutura gerada pode não atender casos específicos sem customização
- **Dependência de Thor**: Requer conhecimento do framework de generators do Rails

## Motivação
Essa abordagem oferece:

- **Automação inteligente**: Reduz trabalho repetitivo mantendo controle sobre a estrutura
- **Consistência garantida**: Todos os bounded contexts seguem o mesmo padrão
- **Velocidade**: Novos artefatos criados em segundos em vez de minutos
- **Padrões documentados**: Generators servem como documentação viva da arquitetura
- **Menor fricção**: Desenvolvedores focam em lógica de negócio, não em estrutura
- **Escalabilidade**: Fácil adicionar novos bounded contexts conforme o projeto cresce

## Implementação

Os generators estão localizados em `lib/generators/` e seguem o padrão Thor do Rails:

```
lib/generators/
├── domain/
│   ├── domain_generator.rb
│   └── templates/
│       └── domain.rb.tt
├── domain_entity/
│   ├── domain_entity_generator.rb
│   └── templates/
│       └── entity.rb.tt
├── domain_service/
│   ├── domain_service_generator.rb
│   └── templates/
│       └── service.rb.tt
├── domain_value_object/
│   ├── domain_value_object_generator.rb
│   └── templates/
│       └── value_object.rb.tt
├── domain_repository/
│   ├── domain_repository_generator.rb
│   └── templates/
│       └── repository.rb.tt
└── domain_event/
    ├── domain_event_generator.rb
    └── templates/
        └── event.rb.tt
```

### Exemplos de Uso

```bash
# Criar bounded context
bin/rails generate domain Identity

# Criar entidade
bin/rails generate domain_entity Identity User

# Criar serviço
bin/rails generate domain_service Identity RegisterUser

# Criar value object
bin/rails generate domain_value_object Orders Money

# Criar repository
bin/rails generate domain_repository Orders OrderRepository

# Criar domain event
bin/rails generate domain_event Orders OrderCreated
```

## Referências
- [Rails Guides: Generators](https://guides.rubyonrails.org/generators.html)
- [Thor Documentation](https://github.com/rails/thor)
- ADR-013: Identity como Bounded Context para User, Seller, Buyer
