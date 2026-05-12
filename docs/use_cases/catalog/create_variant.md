# 📚 UC-CAT-002: Criar Variante

## 🎯 Objetivo
Seller adiciona nova variação a um produto existente.

## 👥 Atores
- **Seller**: Usuário autenticado responsável pela criação

## 📋 Pré-condições
- Produto existente e ativo
- Permissão para editar produto

## 🔄 Fluxo Principal

### 1. Acessar Formulário
Seller acessa painel → Seleciona produto → Clica em "Adicionar Variante"

### 2. Preencher Dados
Seller preenche formulário com:
- Cor
- Tamanho
- Material
- Peso
- Preço (opcional - usa preço base se não informado)
- Quantidade inicial em estoque
- SKU (opcional - gerado automaticamente)
- Imagens

### 3. Validação
Sistema valida:
- Formato de dados obrigatórios
- Nome único dentro do produto
- Preço positivo
- Quantidade não negativa

### 4. Criar Variante
Sistema cria variante com:
- Status "draft"
- SKU gerado automaticamente
- Relacionamento com produto pai

### 5. Atualizar Estoque
Estoque inicial é definido para a nova variante

## 🔄 Fluxos Alternativos

### Variante Duplicada
Sistema detecta SKU duplicado:
- Exibe erro específico
- Sugere edição da variante existente

### Produto Inexistente
Acesso a produto inexistente:
- Redireciona para listagem de produtos
- Exibe mensagem de erro

## 🔄 Pós-condições

### Variante Criada
- Variante disponível no painel
- Produto pai atualizado
- Notificação de sucesso

### Variante Publicada
- Variante visível no catálogo
- Estoque disponível para venda

## 📊 Regras de Negócio

### Nome da Variante
- Deve ser único dentro do produto
- Máximo 100 caracteres
- Pode conter números e letras

### SKU
- Formato: [PRODUTO]-[VARIANTE]-[COR-TAMANHO]
- Exemplo: [CAMISA]-[AZUL]-[P]
- Gerado automaticamente se não informado

### Preços
- Preço base do produto é usado se variante não tiver preço
- Variações podem ter preços diferentes
- Preços devem ser positivos

### Estoque
- Quantidade inicial deve ser positiva
- Estoque é gerenciado por variante

### Dimensões
- Peso deve ser positivo
- Dimensões devem ser válidas para categoria

## 🔗 Integrações

### API Endpoints
- `POST /api/v1/products/:id/variants` - Criar variante
- `PUT /api/v1/variants/:id` - Atualizar variante
- `GET /api/v1/products/:id/variants` - Listar variantes

### Domain Events
- `VariantCreated` - Variante criada
- `VariantUpdated` - Variante atualizada
- `InventoryUpdated` - Estoque atualizado

### Serviços Envolvidos
- `VariantService` - Lógica de negócio
- `InventoryService` - Gestão de estoque
- `ValidationService` - Validações

## 📝 Observações

- Variantes devem ter fotos de qualidade
- Dimensões devem ser precisas para cálculo de frete
- Logs de auditoria para mudanças de preço
- Interface responsiva para mobile
