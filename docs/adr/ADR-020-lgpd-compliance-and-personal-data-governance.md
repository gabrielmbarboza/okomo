# ADR-020 — LGPD Compliance and Personal Data Governance

> **Status:** Accepted  
> **Data:** 2026-05-17  
> **Responsáveis:** Engenharia de Software, Produto, Jurídico/DPO

## Contexto

O Okomo trata dados pessoais desde o primeiro fluxo do bounded context `Identity`: cadastro, autenticação, confirmação de e-mail, recuperação de senha, onboarding de seller, comunicação por e-mail, auditoria e eventos de domínio.

Privacidade não será tratada como uma etapa posterior de hardening. Como o projeto segue documentation-first, as decisões sobre minimização, consentimento, retenção, anonimização e exportação de dados precisam nascer junto com o modelo de `User`.

A LGPD garante direitos aos titulares e exige que o tratamento de dados pessoais tenha finalidade, base legal, necessidade, segurança, transparência e responsabilização. O Okomo também precisa preservar registros transacionais e fiscais, como `Orders` e `Payments`, portanto exclusão física simples de `users` não é adequada como estratégia padrão.

## Decisão

O Okomo adotará governança de dados pessoais como parte do domínio:

* dados pessoais devem ser minimizados e classificados antes de entrar no modelo;
* `User` será o aggregate root responsável pelo ciclo de vida da conta e por marcadores de privacidade essenciais;
* consentimento será versionado, com data/hora de aceite de Termos de Uso e Política de Privacidade;
* anonimização seletiva será preferida à exclusão física de usuários;
* dados transacionais sujeitos a retenção legal serão preservados, mas desacoplados de dados pessoais diretos sempre que possível;
* eventos de privacidade serão auditáveis e não devem carregar dados pessoais desnecessários;
* dados sensíveis ou de alto risco, como documentos, telefone e endereço, deverão ser criptografados em repouso antes de persistência em produção;
* logs, `inspect`, serialização e eventos técnicos devem redigir dados pessoais por padrão;
* o sistema deverá suportar exportação de dados pessoais e solicitação de anonimização de conta.

## Modelo Inicial de User

Além dos campos de autenticação já previstos, `users` deverá contemplar:

| Campo | Objetivo |
| --- | --- |
| `terms_accepted_at` | Data/hora do aceite dos Termos de Uso |
| `privacy_policy_accepted_at` | Data/hora do aceite da Política de Privacidade |
| `consent_version` | Versão dos documentos aceitos |
| `consent_ip_address` | IP do aceite, quando necessário e proporcional |
| `consent_user_agent` | User-Agent do aceite, quando necessário e proporcional |
| `anonymized_at` | Data/hora de anonimização da conta |
| `deactivated_at` | Data/hora de desativação voluntária |
| `blocked_at` | Data/hora de bloqueio por segurança ou violação |
| `deleted_at` | Soft delete técnico, somente quando necessário |

`deleted_at` não substitui anonimização. Ele só representa remoção lógica técnica quando houver caso operacional específico.

## Eventos de Domínio

Eventos mínimos de privacidade:

* `ConsentAccepted`
* `ConsentRevoked`
* `PersonalDataExportRequested`
* `PersonalDataExportCompleted`
* `AccountAnonymizationRequested`
* `AccountAnonymized`

Eventos de privacidade devem usar identificadores internos (`user_id`, `request_id`, `consent_version`) e evitar e-mail, documento, telefone, endereço ou tokens.

## Consequências

### Positivas

* Reduz risco de retrabalho no `Identity`.
* Cria trilha clara para atender direitos do titular.
* Evita acoplamento indevido entre exclusão de conta e retenção de pedidos/pagamentos.
* Facilita revisão jurídica e auditoria futura.
* Estabelece um padrão reutilizável para novos dados pessoais.

### Custos

* O modelo de `User` fica mais explícito e levemente maior.
* Fluxos de cadastro, login, exportação e anonimização exigirão serviços próprios.
* Eventos e logs precisarão de disciplina adicional de redaction.
* Prazos finais de retenção dependerão de validação jurídica/contábil.

## Alternativas Consideradas

### Exclusão física de User

Rejeitada. Quebra integridade histórica de pedidos, pagamentos, auditoria, antifraude e obrigações fiscais.

### Apenas soft delete

Rejeitada como estratégia única. Soft delete preserva dados pessoais em repouso e não atende, por si só, pedidos de anonimização ou minimização.

### Consentimento sem versão

Rejeitada. Sem versão, o sistema não consegue demonstrar qual documento foi aceito pelo titular.

## Diretrizes de Implementação

* Implementar migrations apenas depois que `docs/data_model/*` estiver atualizado.
* Usar `sensitive_attributes` em entidades com dados pessoais.
* Nunca armazenar tokens em texto plano.
* Não colocar e-mail, documento, telefone ou endereço em payloads de eventos quando `user_id` for suficiente.
* Criar serviços explícitos para exportação e anonimização, em vez de espalhar lógica por controllers.
* Garantir que anonimização preserve IDs técnicos necessários para relacionamento com `Orders`, `Payments`, auditoria e obrigações legais.

## Referências

* Lei nº 13.709/2018 — Lei Geral de Proteção de Dados Pessoais.
* `docs/privacy_lgpd.md`
* `docs/security.md`
* `docs/domain_events.md`
