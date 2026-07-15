# Modelo de Domínio — Okomo

> Este documento apresenta a visão conceitual do domínio do Okomo, descrevendo os principais Bounded Contexts, entidades, agregados e relacionamentos de negócio.

---

# 1. Visão Geral do Domínio

O Okomo é uma plataforma SaaS de e-commerce voltada para pequenos artesãos e empreendedores, permitindo que Sellers criem suas próprias lojas virtuais e gerenciem:

- catálogo de produtos;
- estoque;
- carrinho e checkout;
- pedidos;
- promoções e cupons;
- pagamentos;
- frete e entregas.

A arquitetura do domínio segue os princípios de Domain-Driven Design (DDD) e está organizada em Bounded Contexts.

---

# 2. Bounded Contexts

| Bounded Context | Responsabilidade |
|----------------|----------------|
| Catalog | Gerenciamento de Product e Variant |
| Inventory | Controle de estoque e reservas |
| Cart | Intenção de compra do Buyer |
| Checkout | Orquestração da finalização da compra |
| Orders | Gestão de pedidos e snapshots financeiros |
| Promotions | Promoções, descontos e cupons |
| Payments | Processamento e conciliação de pagamentos |
| Shipping | Cálculo de frete e entregas |
| Store | Gestão da loja (`Seller`) |
| Identity | Usuários, autenticação e autorização |
| DataPrivacy | Governança de dados pessoais, consentimentos, exportação e anonimização |

---

# 3. Modelo Conceitual de Alto Nível

```text
User (Identity Context)
   ├── has_one Seller (optional)
   └── has_one Buyer (optional)

Seller
   └── owns Store
           └── owns Product
                   └── has_many Variant
                           └── has_one Inventory

Buyer
   └── has_one Cart
           └── contains CartItem

Buyer
   └── starts Checkout
           ├── reserves Inventory
           ├── applies Promotions
           ├── creates Payment
           └── confirms Order

Order
   ├── has_many OrderItem
   ├── has_many Payments
   └── has_one Shipment

Promotion
   ├── has_one Coupon (optional)
   ├── has_many PromotionRule
   └── generates Discount
```

Privacidade atravessa o modelo inteiro, mas nasce no `Identity`:

```text
User (Identity Context)
   ├── accepts Consent (terms + privacy policy version)
   ├── requests PersonalDataExport
   └── may be selectively anonymized

Orders / Payments / Audit
   └── retain legal and transactional records without direct personal data when possible
```

---

# 4. Shared Kernel

## Responsabilidade

O Shared Kernel reúne infraestrutura mínima compartilhada entre bounded
contexts, sem carregar regras específicas de negócio.

## Entidades Base

### Shared::Entities::BaseEntity

`Shared::Entities::BaseEntity` é a classe base para entidades de domínio
implementadas como POROs.

**Responsabilidades:**

* fornecer inicialização automática baseada em atributos declarados
* registrar atributos com `attributes`
* registrar atributos individuais e defaults com `attribute`
* executar validações declarativas com `validates`
* preservar igualdade e `hash` entre entidades

**Atributos Declarativos:**

Entidades podem declarar múltiplos atributos com `attributes`:

```ruby
attributes :email, :password_digest, :status
```

Para defaults, a entidade usa `attribute`:

```ruby
attribute :created_at, default: -> { Time.current }
attribute :user_roles, default: -> { [] }
```

Defaults callable são avaliados por instância, evitando compartilhamento de
objetos mutáveis entre entidades.

**Inicialização Automática:**

O `initialize` de `BaseEntity` recebe keyword arguments, atribui valores
informados, aplica defaults ausentes e executa `validate!`.

**Suporte a Validações:**

Validações simples são declaradas com `validates`:

```ruby
validates :email, presence: true
validates :status, inclusion: { in: VALID_STATUSES }
```

As validações suportadas inicialmente são:

* `presence: true` - rejeita `nil`, strings em branco e coleções vazias
* `inclusion: { in: [...] }` - exige que o valor pertença à coleção configurada

**Decisão Arquitetônica:**

A infraestrutura permanece independente de ActiveModel e ActiveRecord. O
domínio continua framework-agnostic, e integrações com persistência ou APIs
devem permanecer fora das entidades.

---

# 5. Bounded Context: Identity

## Responsabilidade

Gerenciamento de usuários, autenticação, autorização e papéis de negócio.

## Agregados

### User (Aggregate Root)

`User` é a entidade raiz que representa uma conta de acesso à plataforma.

**Atributos:**

* `id` (UUID) - Identificador único
* `email` (string, único) - Endereço de e-mail do usuário
* `password_digest` (string) - Hash da senha utilizando bcrypt
* `status` (enum: pending_confirmation, active, blocked, deactivated) - Estado da conta
* `email_confirmed_at` (datetime, nullable) - Data de confirmação do e-mail
* `terms_accepted_at` (datetime, nullable) - Data de aceite dos Termos de Uso
* `privacy_policy_accepted_at` (datetime, nullable) - Data de aceite da Política de Privacidade
* `consent_version` (string, nullable) - Versão dos documentos aceitos
* `consent_ip_address` (string, nullable) - IP usado no aceite, quando aplicável
* `consent_user_agent` (string, nullable) - User-Agent usado no aceite, quando aplicável
* `blocked_at` (datetime, nullable) - Data de bloqueio
* `deactivated_at` (datetime, nullable) - Data de desativação
* `anonymized_at` (datetime, nullable) - Data de anonimização seletiva
* `deleted_at` (datetime, nullable) - Soft delete técnico, quando aplicável
* `created_at` (datetime) - Data de criação
* `updated_at` (datetime) - Última atualização

**Relacionamentos:**

* `has_many :user_roles` - Atribuições de roles (Auditável)
* `has_one :seller_profile` (opcional) - Perfil de vendedor se aplicável

**Invariantes:**

* Todo User com `email_confirmed_at` preenchido recebe automaticamente o role `buyer`
* O role `buyer` não pode ser revogado após atribuição
* Um User bloqueado não pode fazer login ou realizar ações
* Um User anonimizado não pode fazer login
* Consentimento deve preservar data, versão dos documentos e, quando proporcional, metadados técnicos de prova
* Exclusão física de User não é a estratégia padrão; anonimização seletiva preserva integridade de Orders, Payments e auditoria

---

### Consent (Value Object / Audit Record)

`Consent` representa o aceite versionado dos Termos de Uso e da Política de Privacidade.

**Atributos:**

* `terms_accepted_at` (datetime) - Data do aceite dos Termos de Uso
* `privacy_policy_accepted_at` (datetime) - Data do aceite da Política de Privacidade
* `consent_version` (string) - Versão do conjunto de documentos aceitos
* `ip_address` (string, nullable) - IP registrado quando necessário
* `user_agent` (string, nullable) - User-Agent registrado quando necessário

**Invariantes:**

* Um User ativo deve ter aceite válido dos documentos obrigatórios do produto.
* Mudança material nos documentos pode exigir novo aceite.
* Eventos e logs devem evitar armazenar cópia integral dos documentos ou dados pessoais desnecessários.

---

### PersonalDataExport (Process)

`PersonalDataExport` representa a solicitação autenticada de exportação de dados pessoais do titular.

**Características:**

* deve ser solicitada por User autenticado ou canal validado;
* deve gerar arquivo ou payload com dados pessoais do titular;
* deve registrar solicitação e conclusão por eventos;
* deve expirar ou ser removida após prazo operacional curto.

---

### AccountAnonymization (Process)

`AccountAnonymization` representa a anonimização seletiva de uma conta.

**Características:**

* preserva chaves técnicas necessárias para integridade transacional;
* remove ou substitui nome, e-mail, documentos, telefone e endereço quando permitido;
* invalida credenciais, tokens e sessões;
* marca `anonymized_at`;
* publica evento auditável.

---

### Role (Entity / Catálogo Global)

`Role` representa o catálogo global e explícito de papéis da plataforma.
Embora tenha comportamento simples nesta fase, é modelado como entidade do
Identity domain para manter identidade própria, nomenclatura estável e
consistência com `UserRole`.

**Atributos:**

* `id` (UUID) - Identificador único
* `name` (enum: buyer, seller, platform_admin) - Nome do role
* `description` (string) - Descrição do role
* `created_at` (datetime) - Data de criação
* `updated_at` (datetime) - Última atualização

**Características:**

* Não muda frequentemente
* Gerenciado apenas por administradores do sistema
* Cada role tem um conjunto específico de permissões
* Roles válidos no MVP: `buyer`, `seller`, `platform_admin`

---

### UserRole (Entity)

`UserRole` representa a atribuição auditável de um `Role` a um `User` em um ponto específico no tempo.
Ele não é apenas uma tabela de junção: preserva o histórico completo de
concessão e revogação de papéis.

**Atributos:**

* `id` (UUID) - Identificador único
* `user_id` (UUID, FK) - Referência ao User
* `role_id` (UUID, FK) - Referência ao Role
* `granted_at` (datetime) - Data de concessão do role
* `revoked_at` (datetime, nullable) - Data de revogação (null = ativo)
* `granted_by_user_id` (UUID, FK, nullable) - Qual usuário concedeu o role
* `revoked_by_user_id` (UUID, FK, nullable) - Qual usuário revogou o role
* `reason` (string, nullable) - Motivo da concessão/revogação
* `created_at` (datetime)
* `updated_at` (datetime)

**Características:**

* Fornece trilha de auditoria completa
* Preserva histórico de todas as concessões e revogações
* `revoked_at` é NULL enquanto o role está ativo para o usuário
* O role `buyer` nunca pode ser revogado (revoked_at permanece NULL)
* Roles adicionais, como `seller` e `platform_admin`, podem ser concedidos e revogados ao longo do tempo

**Relacionamentos:**

* `belongs_to :user`
* `belongs_to :role`
* `belongs_to :granted_by_user` (User, optional)
* `belongs_to :revoked_by_user` (User, optional)

---

### SellerProfile (Entity)

`SellerProfile` representa o perfil de um vendedor, incluindo dados comerciais e status de moderação.

**Atributos:**

* `id` (UUID) - Identificador único
* `user_id` (UUID, FK, único) - Referência ao User (um-para-um)
* `display_name` (string) - Nome da loja exibido publicamente
* `description` (text, nullable) - Descrição da loja
* `status` (enum: pending_review, approved, rejected, suspended) - Estado da aplicação
* `document_type` (enum: cpf, cnpj, mei) - Tipo de documento fiscal
* `document_number` (string) - Número do documento (criptografado em repouso)
* `legal_name` (string) - Razão social ou nome legal
* `contact_email` (string) - E-mail de contato comercial
* `contact_phone` (string) - Telefone de contato
* `commercial_address` (jsonb) - Endereço comercial (rua, número, cidade, estado, CEP)
* `requested_at` (datetime) - Data da solicitação
* `reviewed_at` (datetime, nullable) - Data da análise
* `reviewed_by_user_id` (UUID, FK, nullable) - Qual administrador revisou
* `approved_at` (datetime, nullable) - Data de aprovação
* `rejected_at` (datetime, nullable) - Data de rejeição
* `rejection_reason` (text, nullable) - Motivo da rejeição
* `suspended_at` (datetime, nullable) - Data de suspensão
* `suspension_reason` (text, nullable) - Motivo da suspensão
* `created_at` (datetime)
* `updated_at` (datetime)

**Relacionamentos:**

* `belongs_to :user`
* `belongs_to :reviewed_by_user` (User, optional)

**Estados:**

1. **pending_review** - Inicial, aguardando análise
2. **approved** - Aprovado, pode vender
3. **rejected** - Rejeitado, não pode vender
4. **suspended** - Suspenso temporariamente

**Transições Válidas:**

```
pending_review → approved (sucesso)
pending_review → rejected (rejeição)
approved → suspended (violação)
suspended → approved (resolução)
```

---

## Casos de Uso

### Register User

Criação de nova conta de usuário na plataforma.

**Fluxo:**

1. Valida e-mail (formato e unicidade)
2. Valida força da senha
3. Registra aceite dos Termos de Uso e da Política de Privacidade com versão
4. Cria User com `status = pending_confirmation`, `password_digest` e marcadores de consentimento
5. Gera token seguro de confirmação de e-mail
6. Envia e-mail de confirmação
7. Publica eventos `UserRegistered` e `ConsentAccepted`

**Pós-condições:**

* User criado mas não pode fazer compras
* E-mail de confirmação enviado
* Consentimento obrigatório registrado e auditável

---

### Confirm Email

Confirmação do endereço de e-mail do usuário.

**Fluxo:**

1. Valida token de confirmação (expiração, existência)
2. Marca `email_confirmed_at` com timestamp
3. Altera `status` para `active`
4. Cria automaticamente `UserRole` com `buyer` role
5. Publica evento `UserEmailConfirmed`

**Pós-condições:**

* User pode fazer login
* User recebeu role `buyer`
* UserRole criado e auditável

**Regra Fundamental:**

* `buyer` é o papel base de todo User confirmado e não pode ser revogado

---

### Authenticate User

Autenticação do usuário na plataforma via credenciais.

**Fluxo:**

1. Valida credenciais (email + password)
2. Valida que User não está bloqueado
3. Valida que User confirmou e-mail
4. Gera JWT token com informações do usuário
5. Retorna token e informações básicas
6. Publica evento `UserAuthenticated`

---

### Request Password Recovery

Solicitação de recuperação de senha.

**Fluxo:**

1. Valida existência do e-mail
2. Gera token seguro de recuperação (expiração: 1 hora)
3. Envia e-mail com link seguro
4. Publica evento `PasswordRecoveryRequested`

---

### Reset Password

Redefinição de senha via token.

**Fluxo:**

1. Valida token de recuperação
2. Atualiza `password_digest`
3. Invalida token (não reutilizável)
4. Publica evento `PasswordResetCompleted`

---

### Request Personal Data Export

Solicitação autenticada de exportação de dados pessoais.

**Fluxo:**

1. Valida identidade do titular
2. Registra solicitação de exportação
3. Publica evento `PersonalDataExportRequested`
4. Compila dados pessoais por bounded context
5. Disponibiliza exportação por canal seguro e prazo limitado
6. Publica evento `PersonalDataExportCompleted`

---

### Request Account Anonymization

Solicitação de anonimização seletiva da conta.

**Fluxo:**

1. Valida identidade do titular
2. Verifica retenções obrigatórias em Orders, Payments, auditoria, antifraude e registros fiscais
3. Remove ou substitui dados pessoais diretos quando permitido
4. Invalida credenciais, sessões e tokens
5. Marca `anonymized_at`
6. Publica eventos `AccountAnonymizationRequested` e `AccountAnonymized`

**Pós-condições:**

* Conta não pode mais fazer login
* Dados transacionais legalmente necessários permanecem íntegros
* Dados pessoais diretos são removidos ou substituídos quando permitido

---

### Request Seller Application

Solicitação para se tornar vendedor.

**Fluxo:**

1. Valida que User não é bloqueado ou deativado
2. Valida dados fiscais (documento, formato)
3. Valida dados comerciais (nome da loja, contatos)
4. Cria `SellerProfile` com `status = pending_review`
5. Define `requested_at` com timestamp
6. Publica evento `SellerApplicationSubmitted`

**Pós-condições:**

* SellerProfile criado aguardando revisão
* User ainda não possui role `seller`

---

### Role Lifecycle

Papéis são concedidos e revogados por meio de `UserRole`.

**Fluxo:**

1. Um role global existente em `Role` é selecionado.
2. Um novo `UserRole` é criado com `granted_at`, `granted_by_user_id` e `reason`.
3. Enquanto `revoked_at` for `NULL`, o role está ativo.
4. Para revogar, o mesmo `UserRole` recebe `revoked_at`, `revoked_by_user_id` e motivo.
5. Uma nova concessão futura cria outro `UserRole`, preservando o histórico anterior.

**Invariantes:**

* `buyer` é atribuído automaticamente após confirmação de e-mail.
* `buyer` não pode ser revogado.
* `seller` depende do fluxo de aprovação de `SellerProfile`.
* `platform_admin` só pode ser concedido por operação administrativa explícita.

---

### Seller Approval Flow

O fluxo de vendedor é separado do ciclo de papéis para manter responsabilidades claras.

**Fluxo:**

1. User confirmado submete um `SellerProfile` com `status = pending_review`.
2. Administrador com role `platform_admin` revisa a aplicação.
3. Em caso de aprovação, `SellerProfile` muda para `approved` e o role `seller` é concedido.
4. Em caso de rejeição, `SellerProfile` muda para `rejected` e nenhum role `seller` é concedido.
5. Em caso de suspensão posterior, `SellerProfile` muda para `suspended` e o role `seller` é revogado de forma auditável.

---

### Approve Seller

Aprovação de vendedor por administrador.

**Fluxo:**

1. Valida que revisor possui role `platform_admin`
2. Valida que SellerProfile está em `pending_review`
3. Altera `status` para `approved`
4. Define `approved_at` e `reviewed_by_user_id`
5. Cria `UserRole` com `seller` role
6. Publica evento `SellerApproved`

**Pós-condições:**

* User recebeu role `seller`
* SellerProfile está aprovado
* Pode criar produtos

---

### Reject Seller

Rejeição de vendedor por administrador.

**Fluxo:**

1. Valida que revisor possui role `platform_admin`
2. Valida que SellerProfile está em `pending_review`
3. Altera `status` para `rejected`
4. Define `rejected_at`, `reviewed_by_user_id` e `rejection_reason`
5. Publica evento `SellerRejected`

**Pós-condições:**

* SellerProfile rejeitado
* User não recebe role `seller`

---

### Suspend Seller

Suspensão de vendedor por administrador.

**Fluxo:**

1. Valida que revisor possui role `platform_admin`
2. Valida que SellerProfile está em `approved`
3. Altera `status` para `suspended`
4. Define `suspended_at` e `suspension_reason`
5. Revoga `seller` role (cria UserRole com `revoked_at`)
6. Publica evento `SellerSuspended`

**Pós-condições:**

* SellerProfile suspenso
* User perde role `seller` (auditável)
* Não pode mais vender

---

### Reactivate Seller

Reativação de um seller suspenso por administrador.

**Fluxo:**

1. Valida que revisor possui role `platform_admin`
2. Valida que SellerProfile está em `suspended`
3. Altera `status` de volta para `approved`
4. Limpa `suspended_at` e `suspension_reason`
5. Restaura `seller` role (novo UserRole com granted_at)
6. Publica evento `SellerReactivated`

**Pós-condições:**

* SellerProfile novamente aprovado
* User recupera role `seller`
* Pode vender novamente

---

## Domain Events

### UserRegistered
Novo usuário criado no sistema.

Payload:
* user_id (UUID)
* occurred_at (datetime)

Consumidores típicos:
* SendConfirmationEmailJob
* Audit Logging

### ConsentAccepted
Titular aceitou Termos de Uso e Política de Privacidade.

Payload:
* user_id (UUID)
* consent_version (string)
* terms_accepted_at (datetime)
* privacy_policy_accepted_at (datetime)
* occurred_at (datetime)

Consumidores típicos:
* Audit Logging

### ConsentRevoked
Titular revogou consentimento quando a base legal permitir.

Payload:
* user_id (UUID)
* consent_version (string)
* revoked_at (datetime)
* occurred_at (datetime)

Consumidores típicos:
* Audit Logging

### UserEmailConfirmed
E-mail do usuário confirmado com sucesso.

Payload:
* user_id (UUID)
* occurred_at (datetime)

Consumidores típicos:
* Audit Logging

### UserAuthenticated
Usuário autenticado com sucesso.

Payload:
* user_id (UUID)
* occurred_at (datetime)

Consumidores típicos:
* Audit Logging

### PasswordRecoveryRequested
Usuário solicitou recuperação de senha.

Payload:
* user_id (UUID)
* occurred_at (datetime)

Consumidores típicos:
* SendPasswordRecoveryEmailJob

### PasswordResetCompleted
Senha redefinida com sucesso.

Payload:
* user_id (UUID)
* occurred_at (datetime)

Consumidores típicos:
* Audit Logging

### PersonalDataExportRequested
Titular solicitou exportação de dados pessoais.

Payload:
* user_id (UUID)
* request_id (UUID)
* requested_at (datetime)
* occurred_at (datetime)

Consumidores típicos:
* PersonalDataExportJob
* Audit Logging

### AccountAnonymized
Conta foi anonimizada seletivamente.

Payload:
* user_id (UUID)
* anonymized_at (datetime)
* retention_reason (string, nullable)
* occurred_at (datetime)

Consumidores típicos:
* RevokeSessionsJob
* Audit Logging

### SellerApplicationSubmitted
Solicitação para se tornar vendedor.

Payload:
* user_id (UUID)
* seller_profile_id (UUID)
* occurred_at (datetime)

Consumidores típicos:
* NotifyAdminJob

### SellerApproved
Vendedor aprovado para vender na plataforma.

Payload:
* user_id (UUID)
* seller_profile_id (UUID)
* occurred_at (datetime)

Consumidores típicos:
* NotifySellerApprovalJob
* Audit Logging

### SellerRejected
Vendedor rejeitado na solicitação.

Payload:
* user_id (UUID)
* seller_profile_id (UUID)
* reason (string)
* occurred_at (datetime)

Consumidores típicos:
* NotifySellerRejectionJob
* Audit Logging

### SellerSuspended
Vendedor suspenso temporariamente.

Payload:
* user_id (UUID)
* seller_profile_id (UUID)
* reason (string)
* occurred_at (datetime)

Consumidores típicos:
* NotifySellerSuspensionJob
* Audit Logging

## Regras de Negócio

1. Todo User com e-mail confirmado recebe automaticamente o role buyer.
2. Seller é um role adicional que exige solicitação e aprovação.
3. Um mesmo User pode possuir múltiplos roles simultaneamente.
4. E-mail deve ser único em todo o sistema.
5. Senha deve ter no mínimo 8 caracteres.
6. Tokens de recuperação de senha expiram em 1 hora.
7. Tokens de confirmação de e-mail expiram em 24 horas.
8. SellerProfile passa por moderação manual antes da aprovação.
9. Cadastro exige consentimento versionado para documentos obrigatórios.
10. User anonimizado não pode fazer login.
11. Dados pessoais diretos devem ser removidos ou substituídos em anonimização, preservando registros transacionais obrigatórios.

---

# 6. Bounded Context: Catalog

## Responsabilidade

Gerenciamento de produtos e variantes vendáveis oferecidos por sellers no marketplace.

## Agregados

### Product (Aggregate Root)

`Product` representa um produto conceitual cadastrado por um seller. Agrupa uma ou mais `Variant`, mas não define preço nem estoque diretamente (ADR-007).

**Atributos:**

* `id` (UUID) - Identificador único
* `seller_profile_id` (UUID, FK) - Referência ao SellerProfile dono do produto
* `name` (string) - Nome do produto
* `description` (text, nullable) - Descrição do produto
* `status` (enum: draft, published, archived) - Estado de publicação
* `created_at` (datetime)
* `updated_at` (datetime)

**Relacionamentos:**

* `has_many :variants`

**Invariantes:**

* Todo produto novo inicia como `draft` (BR-CAT-002)
* Produto `draft` não aparece no catálogo público (BR-CAT-003)
* Produto só pode ser publicado com dados obrigatórios preenchidos, ao menos uma `Variant` vendável e descrição suficiente para compra informada (BR-CAT-004)
* Cada produto pertence a exatamente um seller (BR-CAT-007)

---

### Variant (Entity)

`Variant` é a unidade vendável do catálogo. Por decisão da ADR-007, preço e estoque pertencem exclusivamente à Variant, nunca ao Product.

**Atributos:**

* `id` (UUID) - Identificador único
* `product_id` (UUID, FK) - Referência ao Product pai
* `name` (string) - Nome da variante
* `sku` (string) - Identificador único dentro do escopo do produto
* `price` (decimal) - Preço da variante
* `weight_grams` (integer, nullable) - Peso, quando informado
* `height_cm` / `width_cm` / `length_cm` (decimal, nullable) - Dimensões, quando informadas
* `status` (enum: draft, published, archived) - Estado de publicação
* `created_at` (datetime)
* `updated_at` (datetime)

**Relacionamentos:**

* `belongs_to :product`

**Invariantes:**

* Uma variant representa a unidade vendável do catálogo (BR-CAT-009)
* SKU deve ser único dentro do escopo do produto ao qual pertence (BR-CAT-010)
* Preço deve ser maior que zero (BR-CAT-011)
* Dimensões e peso, quando informados, devem ser positivos (BR-CAT-012)

---

## Casos de Uso

### Create Product

Cadastro de um novo produto por um seller.

**Fluxo:**

1. Valida `seller_profile_id` e `name` presentes
2. Cria Product com `status = draft`
3. Publica evento `ProductCreated`

### Create Variant

Adição de uma variante vendável a um produto existente.

**Fluxo:**

1. Localiza o Product pelo `product_id`
2. Valida `name`, `sku`, `price` e dimensões (quando informadas)
3. Valida unicidade do `sku` dentro do escopo do produto (BR-CAT-010)
4. Cria Variant com `status = draft`
5. Publica evento `VariantCreated`

### Publish Product

Publicação de um produto no catálogo.

**Fluxo:**

1. Localiza o Product pelo `id`
2. Valida que o Product está `draft` e possui descrição
3. Valida que existe ao menos uma Variant vendável (BR-CAT-004)
4. Transiciona o Product para `published`
5. Publica evento `ProductPublished`

## Fora de Escopo (Fase 3)

* **Category/taxonomia** - conceito referenciado em documentos antigos, mas sem entidade, tabela ou regra de negócio definida.
* **Store** - `docs/ubiquitous_language.md` mencionava Product pertencente a uma Store, mas nenhuma tabela `stores` existe no modelo de dados; Product referencia `seller_profile_id` diretamente.
* **Autorização de seller (BR-CAT-001)** - exigiria consulta cross-context ao status do `SellerProfile` no Identity; não implementado nesta fase.
* **Inventory/estoque (BR-CAT-013)** - fica a cargo do bounded context Inventory (Fase 5).
* **Promoções e preços exibidos (BR-CAT-017)** - fica a cargo do bounded context Promotions (Fase 6).
* **Busca, visibilidade e exibição pública (BR-CAT-003, 005, 006, 015, 016, 018)** - camada de apresentação/API, fora do escopo domain-only.
* **Imagens/mídia** - nenhuma entidade modelada até o momento.
