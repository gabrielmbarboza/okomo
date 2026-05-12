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
- SKU (opcional)
- Preço base
- Dimensões
- Peso
- Imagens

### 3. Validação
Sistema valida:
- Nome obrigatório e único
- Categoria deve existir
- Preço deve ser maior que zero
- Dimensões devem ser positivas

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
- SKU gerado automaticamente
- Status inicial: "draft"

### Produto Publicado
- Produto visível para Buyers
- Estoque disponível para venda
- Notificação de sucesso enviada

## 📊 Regras de Negócio

### Nome de Produto
- Deve ser único por Store
- Máximo 255 caracteres
- Caracteres especiais permitidos

### SKU
- Deve ser único globalmente
- Formato: [LOJA-PRODUTO-COR-TAMANHO]
- Máximo 50 caracteres

### Preços
- Preço base deve ser positivo
- Variantes podem ter preços diferentes
- Preços podem ser decimais (2 casas)

### Estoque
- Quantidade não pode ser negativa
- Estoque inicial definido por variante

## 🔗 Integrações

### API Endpoints
- `POST /api/v1/products` - Criar produto
- `GET /api/v1/products/:id` - Detalhes do produto
- `PUT /api/v1/products/:id` - Atualizar produto
- `POST /api/v1/products/:id/variants` - Adicionar variante

### Domain Events
- `ProductCreated` - Produto criado
- `ProductUpdated` - Produto atualizado
- `ProductActivated` - Produto ativado
- `InventoryUpdated` - Estoque atualizado

### Serviços Envolvidos
- `ProductService` - Lógica de negócio
- `InventoryService` - Gestão de estoque
- `ValidationService` - Validações

## 📝 Observações

- Fotos devem seguir padrões de qualidade
- Produtos digitais precisam de arquivos específicos
- Produtos físicos precisam de dimensões detalhadas
- Logs de auditoria para mudanças de preço
