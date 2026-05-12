# 📚 UC-CAT-003: Publicar Produto

## 🎯 Objetivo
Seller publica um produto no catálogo, tornando-o visível para Buyers.

## 👥 Atores
- **Seller**: Usuário autenticado responsável pela publicação

## 📋 Pré-condições
- Produto existente e com status "draft"
- Variantes configuradas
- Preços definidos
- Estoque disponível configurado

## 🔄 Fluxo Principal

### 1. Acessar Formulário
Seller acessa painel → Seleciona produto draft → Clica em "Publicar"

### 2. Revisar Publicação
Sistema exibe resumo da publicação:
- Nome e descrição do produto
- Todas as variantes
- Preços de cada variante
- Estoque total disponível
- Opções de visibilidade

### 3. Configurar Publicação
Seller define:
- Data e hora de publicação programada
- Canais de distribuição
- Preços promocionais (opcionais)

### 4. Confirmar Publicação
Seller confirma e sistema:
- Produto muda status para "published"
- Notificação enviada para Buyers interessados
- Produto aparece no catálogo público
- Estoque é marcado como disponível

## 🔄 Fluxos Alternativos

### Publicação Programada
- Sistema publica automaticamente na data/hora definida
- Notificação antecipada ao Seller

### Publicação Imediata
- Produto publicado instantaneamente
- Disponibilidade imediata no catálogo

### Produto sem Estoque
- Produto publicado como "out_of_stock"
- Notificação automática quando estoque disponível

## 🔄 Pós-condições

### Produto Publicado
- Produto visível no catálogo
- Status atualizado em todos os marketplaces
- Buyers podem adicionar ao carrinho

### Publicação Falha
- Mensagem de erro específica
- Produto permanece como "draft"
- Log de auditoria gerado

## 📊 Regras de Negócio

### Visibilidade
- Produtos podem ser públicos ou privados
- Produtos privados só visíveis para Buyers autorizados
- Mudanças de visibilidade geram eventos

### Preços
- Preços devem seguir regulamentações
- Preços promocionais devem ter data de validade
- Mudanças de preço geram notificações

### Estoque
- Produto sem estoque não pode ser publicado
- Estoque insuficiente gera alertas
- Estoque atualizado automaticamente

## 🔗 Integrações

### API Endpoints
- `POST /api/v1/products/:id/publish` - Publicar produto
- `PUT /api/v1/products/:id/visibility` - Alterar visibilidade
- `GET /api/v1/products/:id/preview` - Visualizar como público

### Domain Events
- `ProductPublished` - Produto publicado
- `ProductVisibilityChanged` - Visibilidade alterada
- `InventoryUpdated` - Estoque atualizado
- `PriceChanged` - Preço alterado

### Serviços Envolvidos
- `PublishingService` - Lógica de publicação
- `NotificationService` - Envio de notificações
- `ValidationService` - Validações de publicação

## 📝 Observações

- Publicação deve ser idempotente
- Logs detalhados para auditoria
- Interface responsiva para mobile
- Cache de catálogo para performance
- SEO otimizado para buscas
