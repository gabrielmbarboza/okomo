# 📦 Casos de Uso - Orders

## 🎯 Objetivo

Documentar os principais fluxos de gestão de pedidos, incluindo criação, modificação, cancelamento e rastreamento.

---

## 📋 Casos de Uso

### 1. Gestão de Pedidos

#### UC-ORD-001: Criar Pedido
**Descrição**: Buyer cria um novo pedido a partir do carrinho.

**Atores**: Buyer, Sistema

**Pré-condições**:
- Buyer autenticado
- Carrinho com pelo menos um item
- Endereço de entrega configurado

**Fluxo Principal**:
1. Buyer finaliza compra → Sistema cria Order
2. Order recebe ID único
3. OrderItems são criados com snapshots
4. Status inicial: "pending"

**Fluxos Alternativos**:
- Carrinho vazio → Exibir mensagem de erro
- Item sem estoque → Remover item ou sugerir similares
- Erro na criação → Exibir mensagem específica

**Pós-condições**:
- Pedido criado com sucesso
- ID único gerado
- Notificação enviada ao Buyer

---

### 2. Adicionar Item ao Pedido

#### UC-ORD-002: Adicionar Item
**Descrição**: Buyer adiciona novos itens a um pedido existente.

**Atores**: Buyer, Sistema

**Pré-condições**:
- Pedido existente com status "pending"
- Item disponível em estoque

**Fluxo Principal**:
1. Buyer seleciona produto
2. Informa quantidade e variantes
3. Sistema valida disponibilidade
4. OrderItem é criado
5. Totais são recalculados

**Regras de Negócio**:
- Quantidade deve ser positiva
- Preços são snapshots do momento da adição
- Pedido não pode ser modificado após pagamento

**Fluxos Alternativos**:
- Item indisponível → Mensagem de estoque insuficiente
- Pedido já pago → Bloquear modificação

---

### 3. Remover Item do Pedido

#### UC-ORD-003: Remover Item
**Descrição**: Buyer remove itens de um pedido pendente.

**Atores**: Buyer, Sistema

**Pré-condições**:
- Pedido com status "pending"
- Item existente no pedido

**Fluxo Principal**:
1. Buyer seleciona item a remover
2. Sistema valida permissão
3. OrderItem é removido
4. Totais são recalculados
5. Estoque é devolvido

**Regras de Negócio**:
- Apenas itens não pagos podem ser removidos
- Estoque é devolvido imediatamente
- Histórico de alterações é mantido

---

### 4. Cancelar Pedido

#### UC-ORD-004: Cancelar Pedido
**Descrição**: Buyer cancela um pedido pendente.

**Atores**: Buyer, Sistema

**Pré-condições**:
- Pedido com status "pending"
- Nenhum pagamento processado

**Fluxo Principal**:
1. Buyer solicita cancelamento
2. Sistema valida permissão
3. Pedido muda status para "cancelled"
4. Reservas de estoque são liberadas
5. Notificação enviada ao Buyer

**Regras de Negócio**:
- Pedidos pagos não podem ser cancelados
- Pedidos em trânsito não podem ser cancelados
- Cancelamento deve ser justificado

---

### 5. Rastrear Pedido

#### UC-ORD-005: Rastrear Entrega
**Descrição**: Buyer acompanha o status de entrega de seu pedido.

**Atores**: Buyer, Sistema, Transportadora

**Pré-condições**:
- Pedido confirmado
- Endereço de entrega válido

**Fluxo Principal**:
1. Buyer acessa página de rastreamento
2. Sistema exibe status atual
3. Atualizações são feitas em tempo real
4. Notificações são enviadas

**Regras de Negócio**:
- Apenas o dono do pedido pode rastrear
- Histórico completo deve ser mantido
- Previsões de entrega devem ser realistas

---

## 🔗 Integrações

### API Endpoints
- `POST /api/v1/orders` - Criar pedido
- `POST /api/v1/orders/:id/items` - Adicionar item
- `DELETE /api/v1/orders/:id/items/:item_id` - Remover item
- `POST /api/v1/orders/:id/cancel` - Cancelar pedido
- `GET /api/v1/orders/:id/tracking` - Rastrear pedido

### Domain Events
- `OrderCreated` - Pedido criado
- `OrderItemAdded` - Item adicionado
- `OrderItemRemoved` - Item removido
- `OrderCancelled` - Pedido cancelado
- `OrderShipped` - Pedido enviado
- `OrderDelivered` - Pedido entregue

### Serviços Envolvidos
- `OrderService` - Lógica de negócio
- `TrackingService` - Rastreamento de entregas
- `NotificationService` - Envio de notificações

---

## 📝 Observações

- Pedidos devem usar snapshots de preços
- Histórico completo de alterações é obrigatório
- Cancelamentos devem gerar eventos de compensação
- Rastreamento deve ser em tempo real
- Interface deve ser responsiva para mobile
