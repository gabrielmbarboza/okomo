# Guia de Contribuição

Obrigado pelo seu interesse em contribuir com o Okomo! Este guia fornece instruções sobre como configurar o ambiente, executar testes e enviar contribuições.

## Visão Geral do Processo de Contribuição

1. Fork o repositório
2. Crie uma branch para sua feature (`git checkout -b feature/nome-da-feature`)
3. Faça suas alterações seguindo as convenções do projeto
4. Execute os testes e garanta que todos passem
5. Faça commit das alterações seguindo a Conventional Commits
6. Push para sua branch (`git push origin feature/nome-da-feature`)
7. Abra um Pull Request descrevendo suas alterações

## Setup do Ambiente com Docker

O Okomo utiliza Docker e Docker Compose para facilitar a configuração do ambiente de desenvolvimento.

### Pré-requisitos

- Docker
- Docker Compose

### Passos de Configuração

```bash
# 1. Clone o repositório
git clone <repo-url> && cd okomo

# 2. Copie as variáveis de ambiente
cp .env.example .env

# 3. Construa e inicie todos os serviços
docker-compose up --build

# 4. Em outro terminal, crie e migre o banco de dados
docker-compose exec app bundle exec rails db:create db:migrate

# 5. Execute os testes
docker-compose exec app bundle exec rspec
```

### Comandos Úteis

```bash
# Console Rails
docker-compose exec app bundle exec rails console

# Executar migrações
docker-compose exec app bundle exec rails db:migrate

# Executar testes
docker-compose exec app bundle exec rspec

# Executar testes específicos
docker-compose exec app bundle exec rspec spec/path/to/spec.rb

# Executar RuboCop
docker-compose exec app bundle exec rubocop

# Parar todos os serviços
docker-compose down

# Parar e remover volumes (reset de dados)
docker-compose down -v
```

## Execução de Testes

O Okomo utiliza RSpec como framework de testes. Execute a suíte completa de testes antes de enviar qualquer contribuição:

```bash
docker-compose exec app bundle exec rspec
```

### Cobertura de Testes

Mantenha a cobertura de testes acima de 90% para a lógica de domínio. Use SimpleCov para verificar a cobertura:

```bash
docker-compose exec app bundle exec rspec
```

O relatório de cobertura será gerado em `coverage/index.html`.

## Convenção de Commits

Este projeto segue a especificação [Conventional Commits](https://www.conventionalcommits.org/). A estrutura básica é:

```
<tipo>(<escopo>): <descrição>
```

### Tipos Comuns

- `feat`: Nova funcionalidade
- `fix`: Correção de bug
- `docs`: Alterações na documentação
- `test`: Adição ou alteração de testes
- `refactor`: Refatoração de código
- `chore`: Tarefas de manutenção ou configuração

### Exemplos

```
feat(identity): implement user registration
fix(inventory): prevent overselling with pessimistic locking
docs(adr): add ADR-014 for authentication
test(orders): add CreateOrder service specs
refactor(payments): extract gateway interface
chore(ci): configure GitHub Actions
```

## Regras de Pull Request

Ao abrir um Pull Request:

1. **Descreva claramente o propósito**: Explique o que sua PR faz e por que é necessária.
2. **Referencie issues relacionadas**: Se sua PR resolve uma issue, inclua `Fixes #123` na descrição.
3. **Mantenha o foco**: Cada PR deve abordar uma única concern ou feature.
4. **Testes completos**: Inclua testes para novas funcionalidades e atualize testes existentes se necessário.
5. **Documentação atualizada**: Atualize a documentação relevante (README, docs/, etc.) se sua alteração afeta a interface pública ou o comportamento do sistema.
6. **CI/CD passing**: Garanta que todos os checks do CI/CD passem antes de solicitar revisão.

### Processo de Revisão

- Mantenedores revisarão sua PR e fornecerão feedback
- Responda aos comentários e faça as alterações solicitadas
- Após a aprovação, sua PR será mergeada na branch principal

## Código de Conduta

Ao participar deste projeto, você concorda em seguir o [Código de Conduta](CODE_OF_CONDUCT.md). Todos os participantes são esperados a agir com respeito, empatia e profissionalismo.

## Perguntas?

Se você tiver dúvidas sobre o processo de contribuição ou sobre o projeto em geral, sinta-se à vontade para abrir uma issue ou entrar em contato com os mantenedores.

---

Obrigado por contribuir com o Okomo! 🚀
