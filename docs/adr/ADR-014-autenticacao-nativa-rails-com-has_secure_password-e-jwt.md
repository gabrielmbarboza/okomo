# ADR-014 — Autenticação Nativa Rails com has_secure_password e JWT

- **Status:** Accepted
- **Data:** 2026-05-13

---

## Contexto

O Okomo precisa de um sistema de autenticação seguro, escalável e de baixo acoplamento para proteger seus endpoints de API.

Os principais requisitos incluem:

- autenticação por e-mail e senha;
- geração de tokens JWT para autenticação stateless;
- armazenamento seguro de senhas utilizando bcrypt;
- proteção contra ataques comuns;
- suporte futuro a refresh tokens, revogação de tokens e autenticação multifator (MFA).

Foram avaliadas as seguintes alternativas:

1. Devise + JWT;
2. Auth0 ou Firebase Authentication;
3. `has_secure_password` + JWT nativo.

A solução com Devise oferece um conjunto robusto de funcionalidades, porém adiciona abstrações e dependências significativas. Serviços externos como Auth0 e Firebase reduzem o esforço de implementação, mas introduzem custos e dependência de terceiros.

A abordagem com `has_secure_password` e JWT nativo oferece simplicidade, transparência e controle total sobre o fluxo de autenticação.

---

## Decisão

O Okomo adotará a autenticação nativa do Rails utilizando:

- `has_secure_password` para hash e verificação de senhas com bcrypt;
- a gem `jwt` para geração e validação de tokens JWT;
- serviços específicos no Bounded Context `Identity` para cada caso de uso.

A implementação seguirá a separação entre:

- entidades de domínio (`Identity::Entities::User`);
- modelos de persistência (`UserRecord` ou `User`);
- serviços de aplicação (`Identity::Services::*`).

Cada responsabilidade será encapsulada em um serviço dedicado, evitando a criação de um serviço genérico de autenticação.

---

## Consequências

### Positivas

- baixo acoplamento com bibliotecas de autenticação de alto nível;
- controle total sobre o fluxo de autenticação;
- segurança baseada em bibliotecas maduras e amplamente utilizadas;
- simplicidade e transparência da implementação;
- escalabilidade por meio de autenticação stateless;
- facilidade para evolução incremental;
- alto valor educacional, permitindo compreender profundamente os mecanismos de autenticação.

### Negativas

- maior esforço inicial de implementação;
- responsabilidade direta pela manutenção do fluxo de autenticação;
- funcionalidades avançadas precisarão ser desenvolvidas incrementalmente.

---

## Arquitetura

### Separação entre Domínio e Persistência

O Okomo seguirá a separação entre entidades de domínio e modelos de persistência:

- `Identity::Entities::User` — entidade de domínio;
- `UserRecord` (ou `User`) — modelo `ActiveRecord` responsável pela persistência e por `has_secure_password`.

### Serviços de Aplicação

Cada responsabilidade será implementada em um serviço específico:

- `Identity::Services::RegisterUser`
- `Identity::Services::AuthenticateUser`
- `Identity::Services::GenerateJwtToken`
- `Identity::Services::DecodeJwtToken`
- `Identity::Services::RefreshJwtToken`

### Estrutura de Arquivos

```text
app/
├── domains/
│   └── identity/
│       ├── entities/
│       │   ├── user.rb
│       │   ├── seller.rb
│       │   └── buyer.rb
│       ├── services/
│       │   ├── register_user.rb
│       │   ├── authenticate_user.rb
│       │   ├── generate_jwt_token.rb
│       │   ├── decode_jwt_token.rb
│       │   └── refresh_jwt_token.rb
│       ├── value_objects/
│       └── repositories/
└── models/
    └── user_record.rb