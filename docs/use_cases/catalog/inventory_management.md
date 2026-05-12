# 📚 UC-CAT-004: Gerenciar Estoque

## 🎯 Objetivo
Seller atualiza quantidade disponível de uma variante no sistema.

## 👥 Atores
- **Seller**: Usuário autenticado responsável pela gestão de estoque

## 📋 Pré-condições
- Variante existente e ativa
- Permissão para gerenciar estoque

## 🔄 Fluxo Principal

### 1. Acessar Painel de Estoque
Seller acessa painel → Seleciona variante

### 2. Atualizar Quantidade
Seller informa nova quantidade disponível → Sistema valida dados

### 3. Confirmar Atualização
Sistema atualiza estoque → Notificação de sucesso enviada

### 4. Histórico de Alterações
Sistema registra todas as mudanças com:
- Quantidade anterior
- Quantidade nova
- Data/hora da alteração
- Responsável pela mudança

## 🔄 Fluxos Alternativos

### Estoque Insuficiente
Sistema detecta quantidade negativa:
- Exibe mensagem de erro
- Bloca atualização
- Sugere ajuste de compra

### Lote de Atualizações
Seller pode atualizar múltiplas variantes:
- Upload em lote via CSV
- Validação em massa
- Processamento assíncrono

## 🔄 Pós-condições

### Estoque Atualizado
- Quantidade refletida no sistema
- Notificação de sucesso
- Logs de auditoria gerados

### Alertas de Estoque
- Estoque baixo gera alerta automático
- Notificação enviada ao Seller

## 📊 Regras de Negócio

### Quantidades
- Quantidade não pode ser negativa
- Estoque mínimo deve ser mantido para segurança
- Ajustes manuais exigem justificativa

### Auditoria
- Todas as alterações devem ser registradas
- Logs imutáveis para compliance

### Segurança
- Apenas Sellers podem alterar estoque
- Validação de permissões obrigatória

## 🔗 Integrações

### API Endpoints
- `GET /api/v1/inventory` - Listar estoque
- `PUT /api/v1/inventory/:id` - Atualizar estoque
- `POST /api/v1/inventory/batch` - Atualizar em lote
- `GET /api/v1/inventory/history/:id` - Histórico de alterações

### Domain Events
- `InventoryUpdated` - Estoque atualizado
- `InventoryAlert` - Alerta de estoque baixo
- `InventoryAdjusted` - Ajuste manual de estoque

### Serviços Envolvidos
- `InventoryService` - Lógica de negócio
- `ValidationService` - Validações
- `NotificationService` - Envio de alertas

## 📝 Observações

- Estoque deve ser atualizado em tempo real
- Cache de estoque para performance
- Integração com sistemas externos via webhooks
- Logs detalhados para auditoria fiscal
