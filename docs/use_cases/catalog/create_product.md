# 📚 UC-CAT-001: Criar Produto

## 🎯 Objetivo
Seller cadastra um novo produto no sistema.

## 👥 Atores
- **Seller**: Usuário autenticado responsável pela criação

## 📋 Pré-condições
- Seller autenticado
- Permissão para gerenciar produtos
- Dados obrigatórios preenchidos

## 🔄 Fluxo Principal

### 1. Acessar Formulário
Seller acessa painel de gestão → Clica em "Novo Produto"

### 2. Preencher Dados
Seller preenche formulário com:
- Nome do produto
- Descrição
- Categoria
- Imagens

> Preço, SKU, dimensões e peso pertencem à Variant, não ao Product (ADR-007) — são definidos ao criar cada variante, não nesta etapa.

### 3. Validação
Sistema valida:
- Nome obrigatório
- Categoria deve existir (fora de escopo na Fase 3 — Category não modelada)

### 4. Criar Produto
Sistema cria produto com status "draft"

### 5. Adicionar Variantes
Seller pode adicionar múltiplas variantes:
- Cores
- Tamanhos
- Materiais
- Preços específicos por variante

### 6. Definir Estoque
Seller informa quantidade disponível por variante

### 7. Publicar Produto
Seller ativa produto:
- Produto fica visível no catálogo
- Status muda para "published"
- Notificação enviada

## 🔄 Fluxos Alternativos

### Produto Duplicado
Sistema detecta SKU duplicado:
- Exibe mensagem de erro
- Sugere edição do produto existente

### Dados Inválidos
Validação falha:
- Campos obrigatórios não preenchidos
- Formato de dados incorreto

## 🔄 Pós-condições

### Produto Criado
- Produto disponível no painel
- Status inicial: "draft"

### Produto Publicado
- Produto visível para Buyers
- Notificação de sucesso enviada

## 📊 Regras de Negócio

### Nome de Produto
- Obrigatório
- Máximo 255 caracteres
- Caracteres especiais permitidos

### SKU
- Não se aplica a Product; SKU é atributo da Variant, único por produto (BR-CAT-010) — ver `create_variant.md`. Formato não é fixado nesta fase.

### Preços
- Não se aplica a Product (ADR-007); preço é atributo exclusivo da Variant, deve ser maior que zero (BR-CAT-011)

### Estoque
- Fora de escopo na Fase 3 (BR-CAT-013, bounded context Inventory)

## 🔗 Integrações

### API Endpoints
- `POST /api/v1/products` - Criar produto
- `GET /api/v1/products/:id` - Detalhes do produto
- `PUT /api/v1/products/:id` - Atualizar produto
- `POST /api/v1/products/:id/variants` - Adicionar variante

### Domain Events
- `ProductCreated` - Produto criado (Fase 3)
- `ProductPublished` - Produto publicado (Fase 3)

Ver `docs/domain_events.md` para a lista completa, incluindo eventos futuros fora do escopo desta fase.

### Serviços Envolvidos
- `Catalog::Services::CreateProduct`
- `Catalog::Services::PublishProduct`

## 📝 Observações

- Fotos devem seguir padrões de qualidade
- Produtos digitais precisam de arquivos específicos
- Produtos físicos precisam de dimensões detalhadas
- Logs de auditoria para mudanças de preço
