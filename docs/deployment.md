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