# 📦 Casos de Uso - Inventory

## 🎯 Objetivo

Documentar os principais fluxos de gestão de estoque, incluindo reservas, liberações e reconciliação.

---

## 📋 Casos de Uso

### 1. Reservar Estoque

#### UC-INV-001: Reservar Estoque para Checkout
**Descrição**: Sistema reserva quantidade de estoque durante o processo de checkout.

**Atores**: Sistema, Checkout Service

**Pré-condições**:
- Checkout iniciado
- Itens no carrinho validados
- Estoque disponível

**Fluxo Principal**:
1. Sistema identifica itens do carrinho
2. Para cada item, solicita reserva à Inventory Service
3. Inventory Service valida disponibilidade
4. Reservas são criadas com expiração
5. Estoque disponível é atualizado

**Fluxos Alternativos**:
- Estoque insuficiente → Remover item do carrinho
- Item indisponível → Sugerir produtos similares
- Timeout na reserva → Retentativa automática

**Pós-condições**:
- Reservas criadas com sucesso
- Timer de expiração iniciado
- Logs de auditoria gerados

---

### 2. Confirmar Reserva

#### UC-INV-002: Confirmar Reserva de Estoque
**Descrição**: Sistema confirma a reserva de estoque quando o pagamento é aprovado.

**Atores**: Sistema, Payment Service

**Pré-condições**:
- Pagamento autorizado
- Reservas pendentes existentes

**Fluxo Principal**:
1. Payment Service notifica sobre pagamento aprovado
2. Inventory Service recebe confirmação
3. Reservas pendentes são confirmadas
4. Estoque disponível é consumido
5. Reservas expiradas são canceladas

**Fluxos Alternativos**:
- Pagamento falhado → Cancelar reservas
- Reserva não encontrada → Erro de processamento

**Pós-condições**:
- Estoque atualizado
- Notificações enviadas (Seller, Buyer)
- Logs de auditoria atualizados

---

### 3. Liberar Estoque

#### UC-INV-003: Liberar Estoque em Falha
**Descrição**: Sistema libera reservas de estoque quando checkout falha ou expira.

**Atores**: Sistema, Checkout Service

**Pré-condições**:
- Checkout falhou ou expirou
- Reservas ativas existentes

**Fluxo Principal**:
1. Checkout Service detecta falha/expiração
2. Sistema solicita liberação de todas as reservas
3. Inventory Service libera estoque reservado
4. Estoque disponível é atualizado
5. Notificação de falha enviada ao Buyer

**Fluxos Alternativos**:
- Liberação parcial → Registrar quais itens foram liberados
- Falha na liberação → Gerar alerta crítica

**Pós-condições**:
- Estoque disponível restaurado
- Logs detalhados para debugging
- Notificação ao Buyer sobre falha no checkout

---

### 4. Reconciliar Estoque

#### UC-INV-004: Reconciliação de Estoque
**Descrição**: Processo batch para reconciliar diferenças entre estoque físico e sistema.

**Atores**: Sistema, Inventory Service

**Pré-condições**:
- Período de reconciliação agendado
- Discrepâncias detectadas

**Fluxo Principal**:
1. Sistema inicia processo de reconciliação
2. Compara estoque físico vs sistema
3. Identifica discrepâncias
4. Gera relatório de ajustes
5. Aplica ajustes no sistema
6. Registra auditoria

**Regras de Negócio**:
- Ajustes devem ter justificativa clara
- Discrepâncias acima de threshold geram alertas
- Processo deve ser repetível e auditável

---

### 5. Ajuste Manual

#### UC-INV-005: Ajuste Manual de Estoque
**Descrição**: Seller realiza ajuste manual no estoque por motivo válido.

**Atores**: Seller

**Pré-condições**:
- Permissão para ajustes de estoque
- Justificativa documentada

**Fluxo Principal**:
1. Seller acessa painel de ajustes
2. Seleciona produto/variante
3. Informa quantidade de ajuste
4. Sistema valida permissão e regras
5. Ajuste é aplicado
6. Auditoria é registrada

**Regras de Negócio**:
- Ajustes positivos exigem documentação
- Ajustes negativos requerem autorização
- Histórico completo deve ser mantido

---

## 🔗 Integrações

### API Endpoints
- `POST /api/v1/inventory/reserve` - Reservar estoque
- `POST /api/v1/inventory/confirm` - Confirmar reserva
- `POST /api/v1/inventory/release` - Liberar estoque
- `POST /api/v1/inventory/reconcile` - Reconciliar estoque
- `GET /api/v1/inventory/:id` - Consultar estoque

### Domain Events
- `InventoryReserved` - Estoque reservado
- `InventoryConfirmed` - Reserva confirmada
- `InventoryReleased` - Estoque liberado
- `InventoryAdjusted` - Ajuste manual realizado
- `InventoryReconciled` - Reconciliação concluída

### Serviços Envolvidos
- `InventoryService` - Lógica de negócio
- `ReservationService` - Gestão de reservas
- `ReconciliationService` - Processos batch

---

## 📝 Observações

- Reservas devem usar pessimistic locking
- Timer de expiração é crítico para performance
- Logs detalhados são essenciais para auditoria
- Reconciliação deve ser executada em horários de baixo tráfego
- Interface deve ser idempotente para operações críticas
