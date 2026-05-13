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
- `UserCreated` - Novo usuário criado
- `UserUpdated` - Usuário atualizado
- `UserActivated` - Usuário ativado
- `UserDeactivated` - Usuário desativado
- `UserPasswordChanged` - Senha do usuário alterada
- `UserEmailVerified` - E-mail do usuário verificado
- `UserEmailChanged` - E-mail do usuário alterado

#### Seller Events
- `SellerCreated` - Novo seller criado
- `SellerUpdated` - Seller atualizado
- `SellerActivated` - Seller ativado
- `SellerDeactivated` - Seller desativado
- `SellerTaxInfoUpdated` - Informações fiscais do seller atualizadas
- `SellerCommercialInfoUpdated` - Informações comerciais do seller atualizadas
- `SellerVerificationRequested` - Verificação do seller solicitada
- `SellerVerificationCompleted` - Verificação do seller concluída

#### Buyer Events
- `BuyerCreated` - Novo buyer criado
- `BuyerUpdated` - Buyer atualizado
- `BuyerActivated` - Buyer ativado
- `BuyerDeactivated` - Buyer desativado
- `BuyerAddressAdded` - Endereço do buyer adicionado
- `BuyerAddressUpdated` - Endereço do buyer atualizado
- `BuyerAddressRemoved` - Endereço do buyer removido
- `BuyerPreferencesUpdated` - Preferências do buyer atualizadas

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
