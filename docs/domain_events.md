# Domain Events & Event Storming

## Overview

Este documento descreve a estratégia de Domain Events e Event Storming para a arquitetura DDD do projeto Okomo.

## O que são Domain Events?

Domain Events são eventos que representam mudanças de estado importantes no domínio de negócio. Eles são imutáveis e representam fatos que ocorreram no sistema.

### Benefícios

- **Desacoplamento**: Reduz dependências entre bounded contexts
- **Audit Trail**: Histórico completo de mudanças
- **Event Sourcing**: Possibilidade de reconstruir estado a partir de eventos
- **Integrações**: Sistemas externos podem reagir a eventos de negócio

## Event Storming

Event Storming é uma técnica para descobrir eventos de domínio através de workshops colaborativos.

### Processo

1. **Preparação**: Definir bounded context e aggregates
2. **Brainstorming**: Lista todos os eventos possíveis
3. **Categorização**: Agrupar eventos por tipo
4. **Validação**: Verificar consistência e redundância
5. **Documentação**: Criar especificação detalhada

## Eventos Identificados

### Identidade (Identity)

#### User Events

- `UserRegistered` - Novo usuário criou uma conta
  - Quando: Após criação bem-sucedida de User
  - Dados: user_id, created_at
  - Consumidores: SendConfirmationEmailJob, AuditLogging
  - Privacidade: não carregar email quando `user_id` for suficiente

- `UserEmailConfirmed` - E-mail do usuário foi confirmado
  - Quando: Após validação bem-sucedida do token de confirmação
  - Dados: user_id, confirmed_at
  - Consumidores: GrantBuyerRoleJob, SendWelcomeEmailJob, AuditLogging

- `ConsentAccepted` - Titular aceitou Termos de Uso e Política de Privacidade
  - Quando: Durante cadastro ou aceite de nova versão de documentos
  - Dados: user_id, consent_version, terms_accepted_at, privacy_policy_accepted_at, accepted_at
  - Consumidores: AuditLogging
  - Privacidade: IP/User-Agent só entram em metadados protegidos quando necessários e proporcionais

- `ConsentRevoked` - Titular revogou consentimento quando aplicável
  - Quando: Após solicitação válida de revogação
  - Dados: user_id, consent_version, revoked_at
  - Consumidores: AuditLogging, ConsentReviewJob

- `RoleGranted` - Um role foi concedido a um usuário
  - Quando: Após atribuição bem-sucedida de um role
  - Dados: user_id, role_name, granted_by_user_id, granted_at, reason
  - Consumidores: AuthorizationCacheInvalidator, NotificationJob, AuditLogging

- `RoleRevoked` - Um role foi revogado de um usuário
  - Quando: Após revogação bem-sucedida de um role
  - Dados: user_id, role_name, revoked_by_user_id, revoked_at, reason
  - Consumidores: AuthorizationCacheInvalidator, NotificationJob, AuditLogging
  - Observação: O role `buyer` nunca pode ser revogado

- `PasswordRecoveryRequested` - Usuário solicitou recuperação de senha
  - Quando: Após validação do e-mail em pedido de recuperação
  - Dados: user_id, requested_at
  - Consumidores: SendPasswordRecoveryEmailJob, AuditLogging
  - Privacidade: nunca carregar token em texto plano

- `PasswordResetCompleted` - Senha do usuário foi redefinida com sucesso
  - Quando: Após validação do token e atualização da senha
  - Dados: user_id, reset_at
  - Consumidores: SendPasswordChangeNotificationJob, AuditLogging

- `PersonalDataExportRequested` - Titular solicitou exportação dos próprios dados pessoais
  - Quando: Após solicitação autenticada
  - Dados: user_id, request_id, requested_at
  - Consumidores: PersonalDataExportJob, AuditLogging

- `PersonalDataExportCompleted` - Exportação de dados pessoais foi concluída
  - Quando: Após geração segura do pacote de dados
  - Dados: user_id, request_id, completed_at, expires_at
  - Consumidores: NotifyPersonalDataExportReadyJob, AuditLogging
  - Privacidade: o evento não contém o pacote exportado nem URL pública permanente

- `AccountAnonymizationRequested` - Titular solicitou anonimização de conta
  - Quando: Após solicitação autenticada
  - Dados: user_id, request_id, requested_at
  - Consumidores: AccountAnonymizationReviewJob, AuditLogging

- `AccountAnonymized` - Conta foi anonimizada seletivamente
  - Quando: Após remoção/substituição de dados pessoais diretos permitidos
  - Dados: user_id, request_id, anonymized_at, retention_reason
  - Consumidores: RevokeSessionsJob, AuthorizationCacheInvalidator, AuditLogging
  - Privacidade: preserva identificadores técnicos necessários para retenção legal, sem dados pessoais diretos

**Consumidores Típicos:**

- `SendConfirmationEmailJob` - Envia e-mail de confirmação após `UserRegistered`
- `GrantBuyerRoleJob` - Concede automaticamente role `buyer` após `UserEmailConfirmed`
- `SendWelcomeEmailJob` - Envia boas-vindas após `UserEmailConfirmed`
- `AuthorizationCacheInvalidator` - Invalida caches de autorização após `RoleGranted`/`RoleRevoked`
- `NotificationJob` - Notifica usuário sobre mudanças de roles
- `SendPasswordRecoveryEmailJob` - Envia e-mail de recuperação após `PasswordRecoveryRequested`
- `SendPasswordChangeNotificationJob` - Notifica usuário após `PasswordResetCompleted`
- `PersonalDataExportJob` - Compila dados pessoais do titular após `PersonalDataExportRequested`
- `NotifyPersonalDataExportReadyJob` - Notifica titular quando exportação estiver pronta
- `AccountAnonymizationReviewJob` - Verifica retenções obrigatórias antes de anonimizar
- `RevokeSessionsJob` - Invalida sessões e tokens após anonimização
- `AuditLogging` - Registra todos os eventos para auditoria e compliance

---

#### SellerProfile Events

- `SellerApplicationSubmitted` - Novo seller solicitou aprovação
  - Quando: Após criação bem-sucedida de SellerProfile com status pending_review
  - Dados: user_id, seller_profile_id, display_name, document_type, requested_at
  - Consumidores: NotifyAdminNewApplicationJob, SendAcknowledgmentEmailJob, AuditLogging

- `SellerApproved` - Seller foi aprovado por administrador
  - Quando: Após mudança de status para approved em SellerProfile
  - Dados: user_id, seller_profile_id, reviewed_by_user_id, approved_at
  - Consumidores: GrantSellerRoleJob, SendApprovalEmailJob, UpdateSellerIndexJob, AuditLogging

- `SellerRejected` - Seller foi rejeitado por administrador
  - Quando: Após mudança de status para rejected em SellerProfile
  - Dados: user_id, seller_profile_id, reviewed_by_user_id, rejection_reason, rejected_at
  - Consumidores: SendRejectionEmailJob, AuditLogging

- `SellerSuspended` - Seller foi suspenso por administrador
  - Quando: Após mudança de status para suspended em SellerProfile
  - Dados: user_id, seller_profile_id, suspension_reason, suspended_at
  - Consumidores: RevokeSellerRoleJob, SendSuspensionEmailJob, DeactivateSellerProductsJob, AuditLogging

- `SellerReactivated` - Seller suspenso foi reativado por administrador
  - Quando: Após mudança de status de suspended para approved
  - Dados: user_id, seller_profile_id, reactivated_by_user_id, reactivated_at
  - Consumidores: RestoreSellerRoleJob, SendReactivationEmailJob, AuditLogging

**Consumidores Típicos:**

- `NotifyAdminNewApplicationJob` - Notifica administradores sobre novas aplicações
- `SendAcknowledgmentEmailJob` - Confirma recebimento de aplicação ao seller
- `GrantSellerRoleJob` - Concede role `seller` após `SellerApproved`
- `SendApprovalEmailJob` - Notifica seller sobre aprovação
- `SendRejectionEmailJob` - Notifica seller sobre rejeição com motivo
- `SendSuspensionEmailJob` - Notifica seller sobre suspensão
- `SendReactivationEmailJob` - Notifica seller sobre reativação
- `RevokeSellerRoleJob` - Revoga role `seller` após `SellerSuspended`
- `RestoreSellerRoleJob` - Restaura role `seller` após `SellerReactivated`
- `DeactivateSellerProductsJob` - Desativa produtos do seller após suspensão
- `UpdateSellerIndexJob` - Atualiza índices de busca após aprovação
- `AuditLogging` - Registra todos os eventos para auditoria

---

### Catálogo (Catalog)

#### Product Events
- `ProductCreated` - Novo produto criado
- `ProductUpdated` - Produto atualizado
- `ProductPriceChanged` - Preço do produto alterado
- `ProductActivated` - Produto ativado
- `ProductDeactivated` - Produto desativado
- `ProductDiscontinued` - Produto descontinuado
- `ProductInventoryUpdated` - Estoque do produto atualizado

#### Category Events
- `CategoryCreated` - Nova categoria criada
- `CategoryUpdated` - Categoria atualizada
- `CategoryDeleted` - Categoria removida

### Pedidos (Orders)

#### Order Events
- `OrderCreated` - Pedido criado
- `OrderUpdated` - Pedido atualizado
- `OrderConfirmed` - Pedido confirmado
- `OrderCancelled` - Pedido cancelado
- `OrderPaymentStarted` - Início do processamento de pagamento
- `OrderPaymentCompleted` - Pagamento do pedido concluído
- `OrderPaymentFailed` - Falha no pagamento do pedido
- `OrderShipmentStarted` - Início do envio do pedido
- `OrderShipped` - Pedido enviado
- `OrderDelivered` - Pedido entregue

#### Order Item Events
- `OrderItemAdded` - Item adicionado ao pedido
- `OrderItemRemoved` - Item removido do pedido
- `OrderItemQuantityUpdated` - Quantidade do item atualizada
- `OrderItemPriceUpdated` - Preço do item atualizado

### Pagamentos (Payments)

#### Payment Events
- `PaymentStarted` - Pagamento iniciado
- `PaymentCompleted` - Pagamento concluído
- `PaymentFailed` - Pagamento falhou
- `PaymentRefunded` - Pagamento reembolsado
- `PaymentCancelled` - Pagamento cancelado

### Estoque (Inventory)

#### Inventory Events
- `InventoryReserved` - Estoque reservado
- `InventoryReleased` - Estoque liberado
- `InventoryDepleted` - Estoque esgotado
- `InventoryRestocked` - Estoque reabastecido
- `InventoryAdjusted` - Ajuste manual de estoque

### Envio (Shipping)

#### Shipping Events
- `ShipmentCreated` - Envio criado
- `ShipmentDispatched` - Envio despachado
- `ShipmentInTransit` - Envio em trânsito
- `ShipmentDelivered` - Envio entregue
- `ShipmentReturned` - Envio devolvido

## Estrutura de Eventos

### Formato

```ruby
# frozen_string_literal: true

module Catalog
  module Events
    class ProductCreated
      attr_reader :product_id, :name, :description, :price, :sku, :occurred_at

      def initialize(product_id:, name:, description:, price:, sku:, occurred_at: Time.current)
        @product_id = product_id
        @name = name
        @description = description
        @price = price
        @sku = sku
        @occurred_at = occurred_at
      end

      def to_h
        {
          product_id: product_id,
          name: name,
          description: description,
          price: price,
          sku: sku,
          occurred_at: occurred_at
        }
      end
    end
  end
end
```

### Metadados Comuns

Todos os eventos devem incluir:
- `event_id` - UUID único do evento
- `aggregate_id` - ID do aggregate raiz
- `aggregate_type` - Tipo do aggregate
- `occurred_at` - Timestamp do evento
- `version` - Versão do evento para evolução

### Privacidade em Eventos

Eventos de domínio devem seguir minimização de dados:

- usar `user_id`, `seller_profile_id`, `order_id` e outros identificadores internos no lugar de e-mail, documento, telefone ou endereço;
- nunca carregar senhas, `password_digest`, tokens em texto plano ou documentos fiscais;
- incluir dados pessoais apenas quando o consumidor não puder resolvê-los com segurança por outro meio;
- tratar IP e User-Agent como metadados protegidos, não como payload público de evento;
- eventos de auditoria devem preservar o fato ocorrido sem transformar o event store em repositório paralelo de dados pessoais.

## Implementação

### 1. Event Store

```ruby
# app/services/event_store.rb
class EventStore
  def self.publish(event)
    # Persistir evento
    # Notificar subscribers
  end

  def self.get_events(aggregate_id, from_version: 0)
    # Recuperar eventos de um aggregate
  end
end
```

### 2. Event Handlers

```ruby
# app/domain_events/handlers/inventory_handler.rb
module InventoryHandler
  def self.handle_product_created(event)
    # Atualizar estoque inicial
    InventoryService.create_initial_stock(event.product_id, event.quantity)
  end

  def self.handle_order_created(event)
    # Reservar itens do pedido
    event.items.each do |item|
      InventoryService.reserve(item.product_id, item.quantity)
    end
  end
end
```

### 3. Aggregate Roots

```ruby
# app/domains/catalog/entities/product.rb
class Product < BaseEntity
  def self.create(params)
    product = new(**params)

    # Publicar evento
    event = Catalog::Events::ProductCreated.new(
      product_id: product.id,
      name: product.name,
      description: product.description,
      price: product.price,
      sku: product.sku
    )

    EventStore.publish(event)
    product
  end
end
```

## Roadmap de Implementação

### Fase 1: Foundation (Sprint 1-2)
- [ ] Implementar estrutura base de eventos
- [ ] Criar Event Store simples
- [ ] Implementar eventos do domínio Catalog
- [ ] Configurar publicação/subscrição

### Fase 2: Expansão (Sprint 3-4)
- [ ] Implementar eventos do domínio Orders
- [ ] Implementar eventos do domínio Payments
- [ ] Criar Event Handlers para sincronização
- [ ] Implementar snapshot strategy

### Fase 3: Integração (Sprint 5-6)
- [ ] Implementar eventos do domínio Inventory
- [ ] Implementar eventos do domínio Shipping
- [ ] Configurar message broker (Redis/RabbitMQ)
- [ ] Implementar eventual consistency

## Ferramentas

### Event Storming Tools
- **Miro/Mural**: Para workshops colaborativos
- **EventStorming.io**: Ferramenta online para storming
- **Miro**: Templates para domain events

### Implementação Técnica
- **Ruby Event Store**: Redis ou PostgreSQL
- **Message Broker**: Sidekiq ou RabbitMQ
- **Event Sourcing**: Opcional, para cenários específicos

## Boas Práticas

1. **Eventos Imutáveis**: Nunca modificar um evento após criado
2. **Nomes Descritivos**: Usar padrão [Entity][Action][PastTense]
3. **Versionamento**: Evoluir eventos com versionamento
4. **Idempotência**: Event handlers devem ser idempotentes
5. **Error Handling**: Tratar falhas na publicação/processamento

## Exemplo Prático

### Flow Completo: Criação de Produto

```ruby
# 1. Service cria produto
product = Catalog::Services::CreateProduct.call(params)

# 2. Evento publicado automaticamente
# EventStore publica ProductCreated

# 3. Inventory reage
InventoryHandler.handle_product_created(event)

# 4. Index atualizado
SearchService.index_product(product)
```

## Conclusão

Domain Events e Event Storming fornecem uma base sólida para:
- **Arquitetura evolutiva**
- **Sistemas distribuíveis**
- **Audit completo**
- **Integrações flexíveis**

Esta abordagem será fundamental para escalabilidade do Okomo e integração com sistemas externos.
