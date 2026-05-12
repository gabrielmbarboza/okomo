# 🛒 Casos de Uso - Checkout

## 🎯 Objetivo

Documentar o fluxo completo de checkout, desde a intenção de compra até a confirmação do pedido, incluindo reservas de estoque, aplicação de promoções e processamento de pagamento.

---

## 📋 Casos de Uso

### 1. Iniciar Checkout

#### UC-CH-001: Criar Checkout a partir do Carrinho
**Descrição**: Buyer inicia o processo de checkout a partir dos itens no carrinho.

**Atores**: Buyer

**Pré-condições**:
- Buyer autenticado
- Carrinho com pelo menos um item
- Endereço de entrega configurado

**Fluxo Principal**:
1. Buyer clica em "Finalizar Compra"
2. Sistema valida carrinho e endereço
3. Checkout é criado com status "pending"
4. Reservas de estoque são iniciadas
5. Promoções aplicáveis são identificadas

**Fluxos Alternativos**:
- Carrinho vazio → Exibir mensagem de erro
- Item sem estoque → Remover item ou sugerir similares
- Endereço inválido → Redirecionar para configuração

**Pós-condições**:
- Checkout criado com ID único
- Estoque reservado para os itens
- Timer de expiração iniciado

---

### 2. Aplicar Cupom

#### UC-CH-002: Aplicar Código de Desconto
**Descrição**: Buyer aplica um cupom de desconto durante o checkout.

**Atores**: Buyer

**Pré-condições**:
- Checkout em andamento
- Código de cupom válido

**Fluxo Principal**:
1. Buyer informa código do cupom
2. Sistema valida cupom (validade, uso, restrições)
3. Desconto é calculado e aplicado ao total
4. Novo total é exibido
5. Cupom é marcado como utilizado

**Regras de Negócio**:
- Cupons não cumulativos (apenas um por pedido)
- Cupom inválido → mensagem de erro específica
- Cupom expirado → mensagem de erro
- Cupom já utilizado → mensagem de erro

**Integrações**:
- Validação via `PromotionService`
- Atualização de totais em tempo real

---

### 3. Selecionar Endereço e Frete

#### UC-CH-003: Escolher Método de Entrega
**Descrição**: Buyer seleciona endereço de entrega e método de frete.

**Atores**: Buyer

**Pré-condições**:
- Checkout em andamento
- Endereços cadastrados no perfil

**Fluxo Principal**:
1. Sistema exibe endereços salvos
2. Buyer seleciona endereço existente ou cadastra novo
3. Métodos de frete disponíveis são calculados
4. Buyer seleciona método preferido
5. Custo de frete é adicionado ao total

**Regras de Negócio**:
- Frete grátis para pedidos acima de valor X
- CEP inválido → solicitar CEP correto
- Endereço de entrega não coberto → informar limitações

**Integrações**:
- Cálculo de frete via `ShippingService`
- Validação de CEP via API externa

---

### 4. Processar Pagamento

#### UC-CH-004: Finalizar Pagamento
**Descrição**: Buyer finaliza o pagamento do pedido.

**Atores**: Buyer

**Pré-condições**:
- Checkout completo com endereço e frete
- Totais calculados

**Fluxo Principal**:
1. Buyer seleciona método de pagamento
2. Sistema redireciona para gateway de pagamento
3. Pagamento é processado
4. Pedido é atualizado para "paid" em caso de sucesso
5. Reservas de estoque são confirmadas

**Regras de Negócio**:
- Múltiplas tentativas de pagamento com cartão
- Timeout de segurança para operações
- Rollback automático em falhas

**Integrações**:
- Gateway de pagamento externo
- Webhooks para confirmação de pagamento
- Processamento assíncrono via Sidekiq

---

### 5. Confirmar Pedido

#### UC-CH-005: Confirmar e Finalizar
**Descrição**: Sistema confirma o pedido e libera recursos.

**Atores**: Sistema

**Pré-condições**:
- Pagamento confirmado
- Estoque reservado

**Fluxo Principal**:
1. Pedido é confirmado
2. Estoque reservado é consumido
3. Número do pedido é gerado
4. Notificações são enviadas (Buyer, Seller)
5. Checkout é finalizado

**Regras de Negócio**:
- Pedido não pode ser cancelado após confirmação
- Estoque deve ser atualizado imediatamente
- Notificações devem ser idempotentes

**Integrações**:
- Atualização de status via `OrderService`
- Envio de emails de confirmação
- Atualização de métricas

---

## 🔗 Integrações

### API Endpoints
- `POST /api/v1/checkout` - Iniciar checkout
- `POST /api/v1/checkout/:id/apply_coupon` - Aplicar cupom
- `POST /api/v1/checkout/:id/select_shipping` - Selecionar frete
- `POST /api/v1/checkout/:id/payment` - Processar pagamento
- `POST /api/v1/checkout/:id/confirm` - Confirmar pedido

### Domain Events
- `CheckoutStarted` - Checkout iniciado
- `InventoryReserved` - Estoque reservado
- `CouponApplied` - Cupom aplicado
- `PaymentProcessed` - Pagamento processado
- `OrderConfirmed` - Pedido confirmado

### Serviços Envolvidos
- `CheckoutService` - Orquestração do fluxo
- `InventoryService` - Reservas de estoque
- `PromotionService` - Validação de cupons
- `ShippingService` - Cálculo de frete
- `PaymentGateway` - Processamento de pagamentos

---

## 📝 Observações

- Checkout deve ser idempotente
- Timer de expiração de 15 minutos
- Reservas de estoque devem ser liberadas em falhas
- Logs detalhados para auditoria
- Interface responsiva e progress indicators
