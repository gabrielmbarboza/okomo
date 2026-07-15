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
- Nome
- SKU (obrigatório, fornecido pelo seller)
- Preço
- Peso e dimensões (opcionais)
- Imagens

> Preço e SKU pertencem exclusivamente à Variant (ADR-007) — Product não define preço base.

### 3. Validação
Sistema valida:
- Nome obrigatório
- SKU obrigatório e único dentro do produto (BR-CAT-010)
- Preço maior que zero (BR-CAT-011)
- Peso e dimensões, quando informados, positivos (BR-CAT-012)

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
- Obrigatório
- Máximo 100 caracteres

### SKU
- Obrigatório, fornecido pelo seller (BR-CAT-010)
- Único dentro do produto (não globalmente); formato não é fixado nesta fase
- Sem geração automática

### Preços
- Obrigatório, exclusivo da Variant (ADR-007) — Product não possui preço
- Deve ser maior que zero (BR-CAT-011)

### Estoque
- Fora de escopo na Fase 3 (BR-CAT-013, bounded context Inventory)

### Dimensões
- Peso e dimensões, quando informados, devem ser positivos (BR-CAT-012)

## 🔗 Integrações

### API Endpoints
- `POST /api/v1/products/:id/variants` - Criar variante
- `PUT /api/v1/variants/:id` - Atualizar variante
- `GET /api/v1/products/:id/variants` - Listar variantes

### Domain Events
- `VariantCreated` - Variante criada (Fase 3)

Ver `docs/domain_events.md` para a lista completa, incluindo eventos futuros fora do escopo desta fase.

### Serviços Envolvidos
- `Catalog::Services::CreateVariant`

## 📝 Observações

- Variantes devem ter fotos de qualidade
- Dimensões devem ser precisas para cálculo de frete
- Logs de auditoria para mudanças de preço
- Interface responsiva para mobile
