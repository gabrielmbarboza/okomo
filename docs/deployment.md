# 10. Deployment Architecture (docs/deployment.md)

## Docker & Runtime
- Imagens baseadas em `ruby:3-slim`.
- Uso do **Thruster** para servir assets e compressão.
- `docker-compose` para ambiente local fiel à produção.

## CI/CD
- **GitHub Actions:** Pipeline automatizado de testes e linting.
- **Auto-deploy:** Deploy automático em staging após merge na main.
- **Rollback:** Procedimento via tag de versão no ECR.

## Infraestrutura Cloud
- **Amazon S3:** Bucket para imagens de produtos via Active Storage.
- **CloudFront:** CDN para caching de assets e imagens PII-free.
- **PostgreSQL:** Banco principal da aplicação e armazenamento inicial das filas Solid Queue.
- **Solid Queue:** Backend inicial de background jobs via Active Job, executado por workers dedicados.
- **Redis:** Dependência opcional futura para cache distribuído, rate limiting ou otimizações de escala.

## Background Jobs

O Okomo utiliza Active Job como abstração pública para jobs e Solid Queue como backend inicial. Jobs de aplicação, handlers de Domain Events e rotinas operacionais não devem depender diretamente de APIs específicas de Solid Queue.

### Execução dos Workers

Em desenvolvimento local, os workers podem ser iniciados pelo perfil dedicado do Docker Compose:

```bash
docker-compose --profile with-jobs up
```

Em produção, o processo de worker deve executar o supervisor do Solid Queue:

```bash
bin/jobs start
```

O processo web e o processo de jobs devem ser escalados separadamente. O processo web atende requisições HTTP; o processo Solid Queue consome filas e executa jobs de forma assíncrona.

### Filas

As filas iniciais são:

- `default`: trabalhos assíncronos gerais.
- `mailers`: envio de e-mails e notificações transacionais.
- `events`: handlers de Domain Events entre bounded contexts.
- `maintenance`: rotinas administrativas, reconciliação e limpeza.

Jobs críticos devem declarar explicitamente a fila com `queue_as`, mantendo nomes estáveis e documentados.

### Retry Behavior

Retries devem ser configurados nos próprios jobs com os mecanismos do Active Job, como `retry_on` e `discard_on`. Cada job deve ser idempotente, pois falhas de processo, timeouts e reprocessamentos podem causar execução at-least-once.

Falhas recorrentes devem ser tratadas por runbook operacional antes de reprocessamento manual. Jobs que interagem com gateways externos devem registrar correlação suficiente para auditoria e troubleshooting.

### Concorrência

A concorrência inicial deve ser conservadora para evitar pressão desnecessária no PostgreSQL. A configuração de workers e threads deve ser revisada com base em métricas reais de fila, tempo de execução, locks e uso de conexões.

O pool de conexões do banco deve considerar processos web e processos Solid Queue. Em produção, o limite de conexões do PostgreSQL deve ser dimensionado antes de aumentar o número de workers.

### Considerações de Deploy

As migrations do Solid Queue devem ser aplicadas antes de iniciar workers em uma nova versão. Durante deploys, workers devem ser finalizados de forma graciosa para permitir conclusão ou reentrega segura dos jobs.

Redis não é necessário para processamento de jobs no desenho inicial. Caso seja introduzido futuramente, seu uso deve ser documentado como cache, rate limiting ou evolução de escala, não como dependência do domínio.

## Gestão de Versões e Upgrades

O projeto segue uma política contínua de atualização de dependências para garantir segurança, performance e estabilidade. Consulte [ADR-016: Política Contínua de Atualização de Ruby, Rails e Dependências](adr/ADR-016-continuous-upgrade-policy.md) para detalhes sobre:

- Cadência recomendada para diferentes tipos de atualização (patch, minor, major)
- Critérios de aceitação para upgrades
- Ferramentas de automação (Dependabot ou Renovate)
- Estratégia de rollback para cada tipo de atualização
- Processo de validação em staging antes de produção
