# ADR-016: Política Contínua de Atualização de Ruby, Rails e Dependências

## Status
Aceito

## Contexto

O Okomo é construído sobre Ruby on Rails 8, PostgreSQL 16, Redis 7 e um ecossistema de gems que formam a base técnica do projeto. Como aplicação de longa vida, é fundamental manter as dependências atualizadas para garantir:

- **Segurança:** Vulnerabilidades em bibliotecas antigas podem comprometer a plataforma
- **Performance:** Novas versões frequentemente incluem otimizações críticas
- **Estabilidade:** Versões antigas recebem menos suporte e correções de bugs
- **Compatibilidade:** Manter-se próximo das versões oficialmente suportadas reduz riscos de incompatibilidade futura
- **Conformidade:** Padrões de segurança e conformidade regulatória podem exigir versões recentes

Atualmente, o projeto não possui uma política formal de atualização, criando risco de acumulação de dívida técnica. Sem uma estratégia contínua, atualizações futuras podem se tornar custosas e arriscadas.

Foram avaliadas alternativas:

- **Atualização manual sem política:** Reativa, propensa a atrasos, difícil de justificar prioridade
- **Atualização contínua agressiva:** Risco de instabilidade produtiva e tempo excessivo gasto em migrações
- **Política estruturada com automação:** Proativa, previsível, automatizável, com controle de risco

## Decisão

O Okomo adota uma **política contínua de atualização** de Ruby, Rails, gems e dependências de infraestrutura, suportada por automação com Dependabot ou Renovate. A política estabelece cadências diferentes de atualização conforme o tipo e a severidade:

### Cadência Recomendada

| Tipo de Atualização | Severidade | Cadência | Tratamento |
|---|---|---|---|
| Vulnerabilidades críticas | Crítica | Imediata | Deploy em produção sem aguardar ciclo |
| Ruby patch releases | Alta | Mensal | Prioridade alta, incluir em ciclo mensal |
| Rails patch releases | Alta | Mensal | Prioridade alta, incluir em ciclo mensal |
| Gems patch releases | Alta | Mensal | Prioridade alta, incluir em ciclo mensal |
| Rails minor releases | Média | Trimestral | Planejado, com time dedicado |
| Ruby minor releases | Média | Trimestral | Planejado, com time dedicado |
| Gems minor releases | Média | Trimestral | Planejado, conforme relevância |
| Rails major upgrades | Baixa | Anual ou sob demanda | Projeto dedicado, planning específico |
| Ruby major upgrades | Baixa | Anual ou sob demanda | Projeto dedicado, planning específico |
| Infraestrutura (PostgreSQL, Redis, Docker) | Média a Alta | 6 meses a anual | Coordenado com períodos de menor atividade |

### Dependências em Escopo

1. **Linguagem e Framework:**
   - Ruby
   - Ruby on Rails

2. **Infraestrutura:**
   - PostgreSQL
   - Redis
   - Docker
   - Thruster

3. **Gems Críticas (Aplicação):**
   - sidekiq
   - jwt
   - bcrypt
   - active-record-encryption

4. **Gems Críticas (Testes e Qualidade):**
   - rspec
   - rspec-rails
   - factory_bot
   - rubocop
   - brakeman
   - bundler-audit

5. **Dependências de Build:**
   - bundler
   - Gems com security vulnerabilities

## Estratégia de Atualização

### 1. Identificação e Notificação

- **Dependabot ou Renovate** monitora continuamente o repositório em busca de novas versões
- Alertas de segurança recebem tratamento imediato
- Pull requests automatizadas criadas conforme a cadência definida

### 2. Avaliação

- Review automático de:
  - Changelog da versão
  - Breaking changes
  - Patches de segurança conhecidos
  - Impacto potencial na aplicação

### 3. Testes e Validação

- Build suite completo executado (linting, testes unitários, integração)
- Sem falhas no CI/CD antes de merge
- Testes incluem compatibilidade com outras dependências

### 4. Staging e Produção

- Merge para `main` dispara deploy automático em staging
- Validação em staging antes de deploy em produção
- Monitoramento pós-deploy em produção por 24h

### 5. Rollback

- Estratégia de rollback documentada para cada tipo de atualização
- Major upgrades possuem plano de rollback específico
- Tags de versão e snapshots de infraestrutura mantidos

## Critérios de Aceitação

Uma atualização é considerada **aceita** quando:

1. ✅ Build CI/CD verde (todos os testes e linting passam)
2. ✅ Sem vulnerabilidades críticas ou de alta severidade
3. ✅ Compatibilidade verificada com dependências principais
4. ✅ Validação em staging sem anomalias
5. ✅ Logs de produção sem erros críticos por 24h após deploy
6. ✅ Rollback plan documentado e testado

## Ferramentas de Automação

### Dependabot (Recomendado para GitHub)

**Vantagens:**
- Integração nativa com GitHub
- Suporte multi-linguagem
- Automerge para patch releases com testes verdes
- Notificações claras de segurança
- Sem custo adicional

**Configuração:**

```yaml
# .github/dependabot.yml
version: 2
updates:
  - package-ecosystem: "bundler"
    directory: "/"
    schedule:
      interval: "weekly"
      day: "monday"
      time: "03:00"
    open-pull-requests-limit: 10
    reviewers:
      - "engineering-team"
    labels:
      - "dependencies"
    milestone: 1
    
  - package-ecosystem: "docker"
    directory: "/"
    schedule:
      interval: "weekly"
      day: "monday"
      time: "03:30"
    reviewers:
      - "devops-team"
      
  - package-ecosystem: "github-actions"
    directory: "/"
    schedule:
      interval: "weekly"
      day: "monday"
      time: "04:00"
```

### Renovate (Alternativa Universal)

**Vantagens:**
- Maior flexibilidade em regras de automação
- Suporte para múltiplos ecosistemas
- Grouping e batching automático
- Renovate Bot com IA para análise
- Free tier genero

**Configuração:**

```json
// renovate.json
{
  "extends": [
    "config:base",
    "schedule:weekly",
    "group:allNonMajor"
  ],
  "schedule": [
    {
      "matchUpdateTypes": ["patch"],
      "schedule": ["before 3am on Monday"]
    },
    {
      "matchUpdateTypes": ["minor"],
      "schedule": ["before 3am on Monday"]
    }
  ],
  "vulnerabilityAlerts": true,
  "rebaseWhenModified": true,
  "semanticCommits": true,
  "automerge": true,
  "automergeType": "pr",
  "automergeStrategy": "squash"
}
```

## Motivação

Esta política oferece:

- **Proatividade:** Evita acúmulo de dívida técnica e surpresas com incompatibilidades futuras
- **Segurança:** Reduz janelas de exposição a vulnerabilidades conhecidas
- **Previsibilidade:** Calendário claro permite planejamento e alocação de recursos
- **Automação:** Reduz trabalho manual e falhas de coordenação
- **Controle de risco:** Cadências diferentes para diferentes tipos de atualização
- **Documentação:** Planos claros de rollback e validação
- **Conformidade:** Alinha com boas práticas da indústria e conformidade regulatória

## Implementação

### Fase 1 (Imediata)

- [ ] Configurar Dependabot ou Renovate em `.github/dependabot.yml` ou `renovate.json`
- [ ] Definir responsável por revisão de pull requests de dependências
- [ ] Criar template de PR para atualizações
- [ ] Documentar processo em runbook

### Fase 2 (Primeiras 2 Semanas)

- [ ] Resolver vulnerabilidades críticas existentes
- [ ] Executar primeira rodada de atualizações de patch
- [ ] Avaliar impacto em performance e estabilidade

### Fase 3 (Contínua)

- [ ] Revisar e mergear PRs de atualização conforme agendar
- [ ] Monitorar falhas de compatibilidade
- [ ] Ajustar cadência conforme experiência

## Referências

- [Ruby Version Management](https://www.ruby-lang.org/en/downloads/)
- [Rails Upgrade Guide](https://guides.rubyonrails.org/upgrading_ruby_on_rails.html)
- [Dependabot Documentation](https://docs.github.com/en/code-security/dependabot)
- [Renovate Documentation](https://docs.renovatebot.com/)
- [OWASP: Vulnerable and Outdated Components](https://owasp.org/www-project-top-ten/2021/A06_2021-Vulnerable_and_Outdated_Components)
