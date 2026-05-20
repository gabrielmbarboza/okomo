# ADR-022: Solid Queue como Backend Inicial de Background Jobs

## Status
Aceito

## Contexto

O Okomo precisa executar processamento assíncrono para tarefas como envio de notificações, expiração de reservas de Inventory, reconciliações operacionais, rotinas de privacidade e handlers de Domain Events. A arquitetura do projeto já prevê que essas tarefas sejam expostas pela abstração do Active Job, mantendo o domínio independente de detalhes de infraestrutura.

A configuração inicial previa Sidekiq e Redis como base para background jobs. Essa escolha é madura e amplamente utilizada, mas adiciona uma dependência operacional obrigatória antes de existir uma necessidade comprovada de throughput elevado, filas avançadas ou recursos específicos do ecossistema Sidekiq.

Como o projeto utiliza Rails 8, Solid Queue passa a ser uma opção alinhada ao framework para processamento assíncrono baseado em banco de dados. Isso permite iniciar com menos serviços obrigatórios, mantendo a compatibilidade com Active Job e preservando a possibilidade de migração futura para Sidekiq se a escala da plataforma exigir.

## Decisão

O Okomo utilizará Solid Queue como backend inicial de processamento assíncrono.

O projeto continuará utilizando Active Job como camada de abstração para jobs. Application Jobs, handlers assíncronos e integrações internas devem depender de Active Job, não de APIs específicas de Solid Queue.

O domínio permanecerá desacoplado do backend de jobs. Entidades, Value Objects, Domain Services e Domain Events não devem conhecer Solid Queue, Sidekiq, Redis ou qualquer mecanismo de fila.

Redis deixa de ser dependência obrigatória inicial para background jobs. Ele poderá ser introduzido futuramente para cache distribuído, rate limiting, pub/sub, otimizações de leitura ou outros cenários de escala.

Sidekiq poderá ser adotado futuramente se houver necessidade real de throughput maior, recursos avançados de operação, ecossistema de plugins ou requisitos específicos de processamento distribuído.

## Consequências Positivas

- Menor complexidade operacional no ambiente inicial.
- Menor quantidade de infraestrutura obrigatória para desenvolvimento, CI e produção.
- Melhor alinhamento com Rails 8 e com a configuração padrão de Active Job.
- Menor custo de manutenção inicial.
- Simplicidade para ambiente de desenvolvimento, onboarding e execução local.
- Continuidade da arquitetura baseada em Active Job, preservando portabilidade futura.

## Consequências Negativas

- Solid Queue possui menor maturidade e menor ecossistema de plugins quando comparado ao Sidekiq.
- Throughput pode ser inferior em cenários extremos de alto volume.
- Há menor quantidade de recursos avançados prontos para operação quando comparado ao ecossistema Sidekiq.
- A fila passa a consumir capacidade do PostgreSQL, exigindo monitoramento de tabelas, conexões e retenção de jobs.

## Estratégia de Evolução

O Okomo deve iniciar com Solid Queue e revisar essa decisão conforme métricas reais de produção. A avaliação de migração para Sidekiq deve considerar volume de jobs, latência de processamento, pressão sobre PostgreSQL, custo operacional, necessidade de plugins e complexidade de observabilidade.

Enquanto Solid Queue for o backend principal, os jobs devem continuar idempotentes e seguros para execução at-least-once. Falhas, retries e reprocessamentos devem ser tratados no nível da aplicação e dos casos de uso, não por suposições específicas sobre a implementação da fila.

Redis poderá ser introduzido independentemente de Sidekiq quando houver necessidade de cache distribuído, controle de taxa, sessões, pub/sub ou otimizações de leitura. Essa introdução não deve tornar o domínio dependente de Redis.

Se Sidekiq for adotado futuramente, a migração deve ocorrer na camada de infraestrutura, mantendo Active Job como contrato público da aplicação sempre que possível.

## Motivação

A motivação principal é reduzir complexidade inicial sem abrir mão de processamento assíncrono durável. Solid Queue oferece uma opção suficiente para o estágio atual do Okomo, aproveitando PostgreSQL e Rails 8, enquanto Active Job preserva a liberdade arquitetural para evoluir para Sidekiq ou outro backend no futuro.
