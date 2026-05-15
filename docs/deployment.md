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
- **Redis:** Gerenciamento de filas Sidekiq e Cache de aplicação.
- **Sidekiq:** Workers dedicados para transações financeiras e expiração de estoque.

## Gestão de Versões e Upgrades

O projeto segue uma política contínua de atualização de dependências para garantir segurança, performance e estabilidade. Consulte [ADR-016: Política Contínua de Atualização de Ruby, Rails e Dependências](adr/ADR-016-continuous-upgrade-policy.md) para detalhes sobre:

- Cadência recomendada para diferentes tipos de atualização (patch, minor, major)
- Critérios de aceitação para upgrades
- Ferramentas de automação (Dependabot ou Renovate)
- Estratégia de rollback para cada tipo de atualização
- Processo de validação em staging antes de produção