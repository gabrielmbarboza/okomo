# ADR-017: Modelagem Evolutiva do Modelo de Dados

## Status
Aceito

## Contexto

O Okomo é uma plataforma e-commerce construída sobre princípios de Domain-Driven Design, organizada em múltiplos Bounded Contexts (Identity, Catalog, Inventory, Orders, Checkout, Payments, Shipping, Promotions). Cada contexto possui seus próprios agregados, entidades e relacionamentos.

Historicamente, a modelagem de dados tem sido documentada isoladamente por contexto (ex: `identity.dbml`). Conforme o projeto evolui e novos contextos são implementados, surgem desafios:

1. **Visibilidade limitada de relacionamentos entre contextos**: Difficil entender como Orders integra com Inventory, ou como Promotions impacta Payments
2. **Onboarding complexo**: Novos desenvolvedores precisam ler múltiplos arquivos para compreender a arquitetura global
3. **Impacto de mudanças não óbvio**: Alterar uma entidade em um contexto pode ter implicações em cadeia em outros contextos
4. **Falta de padrão evolutivo**: Não há clareza sobre quando e como o modelo de dados deve ser revisado e evoluir

Avaliaram-se alternativas:

- **Único diagrama monolítico**: Rápido de visualizar, mas não escala; impossível manter com múltiplos contextos em evolução
- **Apenas diagramas específicos por contexto**: Oferece detalhes, mas perde visão de arquitetura
- **Dois níveis: global + contexto-específico**: Visão arquitetônica clara sem perder detalhes onde necessário

## Decisão

O Okomo adota uma **estratégia de modelagem evolutiva em dois níveis**:

### 1. Nível Global (Arquitetônico)

Mantém um **diagrama global consolidado** (`docs/data_model/dbdiagram/okomo_overview.dbml`) que:

- Representa **todas as entidades principais** de todos os Bounded Contexts
- Mostra apenas atributos **essenciais** para entender propriedade e relacionamentos
- Usa UUIDs como chaves primárias de acordo com ADR-003
- Documenta relacionamentos entre contextos de forma clara
- Fornece "bússola arquitetônica" para decisões de design

Este diagrama é:
- **Validado regularmente** durante design reviews de novas features
- **Refatored incrementalmente** conforme a arquitetura evolui
- **Atualizado antes de fase de implementação** para validar relacionamentos
- **Tratado como artefato vivo** que reflete a realidade, não um ideal teórico

### 2. Nível Contexto-Específico (Implementação)

Cada Bounded Context mantém seu próprio diagrama DBML (`docs/data_model/dbdiagram/{context}.dbml`) com:

- **Todas as colunas e tipos de dados** específicos do contexto
- **Constraints, índices e validações** detalhadas
- **Notas técnicas e decisões de design** do contexto
- **Relacionamentos internos** do agregado

Estes diagramas:
- Evoluem independentemente conforme o contexto é implementado
- Servem como **fonte de verdade para migrations Rails**
- São validados antes de cada release do contexto
- Podem diferir ligeiramente do modelo global enquanto este não é sincronizado

### 3. Documentação Arquitetônica

Um documento estratégico (`docs/data_model/overview.md`) articula:

- Responsabilidade de cada Bounded Context
- Descrição de cada entidade principal
- Principais relacionamentos entre contextos
- Fluxos de dados de features críticas (checkout, pedido, etc.)
- Princípios de evolução e escalabilidade futura

## Consequências

### Positivas

- **Clareza arquitetônica**: Novos desenvolvedores entendem a plataforma rapidamente
- **Impacto de mudanças visível**: Alterações em um contexto mostram impactos cascata
- **Evolução planejada**: Decisões de design são tomadas considerando a visão global
- **Escalabilidade**: Facilita futuras extrações de contextos para serviços independentes
- **Documentação viva**: O modelo de dados é articulado como um artefato que cresce com o produto
- **Rastreabilidade**: Cada mudança no modelo está vinculada a um ADR ou design review

### Negativas

- **Sincronização requerida**: O diagrama global precisa ser sincronizado periodicamente com contextos-específicos
- **Complexidade adicional**: Mais um nível de abstração para manter
- **Risco de desalinhamento**: Se o global não for atualizado, gera confusão
- **Custo de mudanças**: Alterações em agregados críticos requerem atualização em múltiplos arquivos

### Mitigações

- **Validação em design reviews**: Mudanças no global são revisadas antes de implementação
- **Checklist de sincronização**: Fase de closing de cada feature inclui sincronização do modelo
- **Automação**: Testes podem validar consistência entre níveis (futura)
- **Governance**: README de data_model documenta processo de evolução

## Implementação

### Artefatos Criados

1. **`docs/data_model/dbdiagram/okomo_overview.dbml`**
   - Diagrama DBML consolidado com todos os contextos
   - Visualizável em [dbdiagram.io](https://dbdiagram.io)
   - Atualizado antes de cada nova fase

2. **`docs/data_model/overview.md`**
   - Documento estratégico em português
   - Descrição de cada contexto e entidade
   - Fluxos de dados principais
   - Princípios de evolução

3. **`docs/data_model/README.md`** (atualizado)
   - Referência ao diagrama global
   - Explicação de relacionamento entre níveis

4. **`ROADMAP.md`** (atualizado)
   - Tarefas de sincronização do modelo durante desenvolvimento

### Processo de Evolução

1. **Proposição de Feature** → Arquiteto valida impacto no modelo global
2. **Design Review** → Diagrama global é atualizado e revisado
3. **Implementação** → Contexto-específico é implementado, evoluindo seu diagrama DBML
4. **Sincronização** → Antes de merge, diagrama global é sincronizado com implementação
5. **Release** → Feature é deployada com modelos atualizados

### Cadência de Revisão

- **Trimestral**: Revisão completa do diagrama global contra todos os contextos-específicos
- **Por Feature**: Revisão do diagrama global antes de iniciar implementação em novo contexto
- **Post-Deploy**: Sincronização com base em mudanças reais de implementação

## Relacionado

- ADR-001: Monólito Modular (organização em Bounded Contexts)
- ADR-003: UUID como Chaves Primárias
- ADR-010: Namespacing de Rotas por Bounded Context
- Documento: `docs/domain.md` - Modelo de Domínio
- Documento: `docs/data_model/overview.md` - Visão Global Consolidada

---

**Última atualização:** Maio de 2026

**Participantes da Decisão:**
- Arquitetura de Software
- Engenharia de Dados
- Domain Experts
