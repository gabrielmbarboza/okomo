# Requisitos Não Funcionais — Okomo

> Este documento define os requisitos não funcionais do Okomo, estabelecendo metas técnicas e operacionais que orientam decisões arquiteturais, infraestrutura, testes e monitoramento.

---

# 1. Objetivo

Garantir que o Okomo seja uma plataforma:

* confiável;
* segura;
* escalável;
* observável;
* performática;
* resiliente;
* fácil de manter e evoluir.

---

# 2. Escopo

Os requisitos descritos neste documento aplicam-se a todos os domínios do sistema, incluindo:

* Catalog;
* Identity;
* Inventory;
* Order;
* Checkout;
* Payment;
* Shipment;
* Coupon.

---

# 3. Performance

## Objetivo

Garantir tempos de resposta adequados para uma boa experiência do usuário.

## Metas Iniciais (MVP)

* 95% das requisições HTTP em até 300 ms;
* 99% das requisições HTTP em até 1 segundo;
* operações críticas de checkout em até 2 segundos, excluindo latência de gateways externos;
* processamento assíncrono de jobs sem bloquear requisições web.

## Operações Críticas

* busca de produtos;
* cálculo de frete;
* aplicação de Coupon;
* reserva de Inventory;
* criação de Order;
* processamento de Payment.

---

# 4. Escalabilidade

## Objetivo

Permitir crescimento gradual sem necessidade de reescrita arquitetural.

## Requisitos

* arquitetura em Modular Monolith;
* suporte a horizontal scaling da aplicação;
* uso de CDN para assets e imagens;
* armazenamento de arquivos em Amazon S3 ou equivalente;
* possibilidade de uso de Read Replicas no PostgreSQL;
* uso de cache para consultas de leitura intensiva.

---

# 5. Disponibilidade

## Objetivo

Garantir continuidade do serviço para Sellers e Buyers.

## Meta Inicial

* disponibilidade mensal de 99,5%.

## Estratégias

* monitoramento contínuo;
* health checks;
* deploy com rollback;
* backups automatizados.

---

# 6. Confiabilidade

## Objetivo

Garantir execução correta e consistente das operações.

## Requisitos

* operações críticas devem ser transacionais;
* processamento idempotente;
* uso de retries controlados;
* compensação em caso de falhas.

---

# 7. Consistência de Dados

## Objetivo

Garantir integridade transacional e prevenir inconsistências.

## Requisitos

* zero overselling;
* uso de Pessimistic Locking em Inventory;
* snapshot financeiro em Order e OrderItem;
* validação de transições de estado;
* constraints no banco de dados.

---

# 8. Segurança

## Objetivo

Proteger dados, transações e acessos.

## Requisitos

* autenticação segura;
* autorização baseada em papéis;
* criptografia de credenciais;
* proteção contra SQL Injection, XSS e CSRF;
* rate limiting;
* logs de auditoria para operações críticas;
* conformidade com a LGPD.

---

# 9. Observabilidade

## Objetivo

Permitir monitoramento, troubleshooting e análise operacional.

## Requisitos

* logs estruturados;
* métricas técnicas e de negócio;
* rastreamento de erros;
* correlação por request_id;
* dashboards operacionais.

## Métricas de Negócio

* número de Orders;
* taxa de conversão;
* abandono de Checkout;
* Inventory Reservations expiradas;
* Payments aprovados e recusados.

---

# 10. Resiliência

## Objetivo

Garantir recuperação adequada diante de falhas.

## Requisitos

* retries exponenciais para integrações externas;
* circuit breakers (futuro);
* jobs assíncronos;
* rollback de transações;
* compensação de reservas de Inventory.

---

# 11. Backup e Recuperação

## Objetivo

Minimizar perda de dados e tempo de indisponibilidade.

## Metas Iniciais

* RTO (Recovery Time Objective): até 4 horas;
* RPO (Recovery Point Objective): até 15 minutos.

## Estratégias

* backups automáticos do PostgreSQL;
* versionamento de arquivos;
* testes periódicos de restauração.

---

# 12. Manutenibilidade

## Objetivo

Facilitar entendimento e evolução do sistema.

## Requisitos

* arquitetura modular;
* documentação atualizada;
* convenções de código;
* ADRs;
* revisão de código.

---

# 13. Testabilidade

## Objetivo

Garantir validação automatizada do comportamento.

## Requisitos

* testes unitários para domínio;
* testes de integração;
* testes de API;
* testes end-to-end;
* cobertura prioritária para Inventory, Checkout e Payment.

---

# 14. Portabilidade

## Objetivo

Permitir execução consistente em diferentes ambientes.

## Requisitos

* uso de Docker;
* configuração via variáveis de ambiente;
* infraestrutura reproduzível.

---

# 15. Compatibilidade

## Stack Principal

* Ruby on Rails 8;
* PostgreSQL;
* Redis;
* Sidekiq;
* Docker.

---

# 16. Compliance

## Requisitos

* conformidade com LGPD;
* trilha de auditoria para operações financeiras;
* retenção adequada de logs.

---

# 17. SLIs e SLOs Iniciais

| Indicador                   | Meta          |
| --------------------------- | ------------- |
| Latência P95                | ≤ 300 ms      |
| Latência P99                | ≤ 1 s         |
| Disponibilidade             | ≥ 99,5%       |
| Overselling                 | 0 ocorrências |
| Taxa de falha no Checkout   | < 1%          |
| Tempo de recuperação (RTO)  | ≤ 4 horas     |
| Perda máxima de dados (RPO) | ≤ 15 minutos  |

---

# 18. Priorização para o MVP

## Críticos

* consistência de dados;
* segurança;
* performance adequada;
* testes automatizados;
* observabilidade básica.

## Evolutivos

* circuit breakers;
* alta disponibilidade avançada;
* escalabilidade extrema.

---

# 19. Relação com Architecture Decision Records

Este documento fundamenta decisões como:

* Modular Monolith;
* PostgreSQL como banco principal;
* UUID como chaves primárias;
* Pessimistic Locking para Inventory;
* Snapshot financeiro em OrderItem.

---

# 20. Revisão Contínua

Os requisitos não funcionais devem ser revisados periodicamente conforme:

* o produto evolui;
* o volume de uso aumenta;
* novos riscos são identificados;
* a arquitetura amadurece.
