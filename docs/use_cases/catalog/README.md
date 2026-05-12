# 📚 Casos de Uso - Catalog

## 🎯 Objetivo

Documentar os principais fluxos de interação com o domínio de Catálogo, incluindo gestão de produtos, variantes e estoque.

---

## 📋 Casos de Uso

### 1. Gestão de Produtos

#### UC-001: Criar Produto
**Descrição**: Seller cadastra um novo produto no sistema.

**Atores**: Seller

**Pré-condições**:
- Seller autenticado
- Dados obrigatórios preenchidos

**Fluxo Principal**:
1. Seller acessa painel de produtos
2. Preenche formulário com dados do produto
3. Sistema valida informações
4. Produto é criado com status "draft"
5. Seller pode adicionar variantes
6. Produto é ativado e publicado

**Fluxos Alternativos**:
- Produto duplicado → Sugerir edição
- Dados inválidos → Exibir erros específicos

**Pós-condições**:
- Produto disponível no catálogo
- Notificação de sucesso
- SKU gerado automaticamente

---

### 2. Gestão de Variantes

#### UC-002: Adicionar Variante
**Descrição**: Seller adiciona nova variação a um produto existente.

**Atores**: Seller

**Pré-condições**:
- Produto existente e ativo
- Permissão para editar produto

**Fluxo Principal**:
1. Seller seleciona produto
2. Clica em "Adicionar Variante"
3. Preenche dados da variante
4. Sistema valida regras (SKU único, preço válido)
5. Variante é criada
6. Estoque inicial é definido

**Regras de Negócio**:
- SKU deve ser único dentro do produto
- Preço deve ser maior que zero
- Dimensões devem ser válidas

---

### 3. Gestão de Estoque

#### UC-003: Atualizar Estoque
**Descrição**: Seller atualiza quantidade disponível de uma variante.

**Atores**: Seller

**Pré-condições**:
- Variante existente
- Permissão para gerenciar estoque

**Fluxo Principal**:
1. Seller acessa painel de estoque
2. Seleciona variante
3. Informa nova quantidade disponível
4. Sistema atualiza estoque
5. Histórico de alterações é registrado

**Regras de Negócio**:
- Quantidade não pode ser negativa
- Mudanças significativas geram alertas
- Estoque mínimo é mantido para segurança

---

### 4. Visualização de Catálogo

#### UC-004: Buscar Produtos
**Descrição**: Buyer busca produtos no catálogo.

**Atores**: Buyer

**Pré-condições**:
- Acesso ao catálogo público

**Fluxo Principal**:
1. Buyer acessa página inicial
2. Utiliza filtros (categoria, preço, nome)
3. Sistema retorna produtos compatíveis
4. Buyer pode visualizar detalhes do produto
5. Variantes disponíveis são exibidas

**Regras de Negócio**:
- Produtos inativos não são exibidos
- Produtos sem estoque são marcados
- Busca ordenada por relevância

---

### 5. Detalhes do Produto

#### UC-005: Visualizar Produto
**Descrição**: Buyer visualiza detalhes completos de um produto.

**Atores**: Buyer

**Pré-condições**:
- Produto existente
- Produto ativo

**Fluxo Principal**:
1. Buyer clica no produto
2. Sistema exibe informações completas:
   - Nome e descrição
   - Todas as variantes disponíveis
   - Preços e estoque
   - Especificações técnicas
   - Fotos e vídeos
3. Buyer pode adicionar ao carrinho

**Regras de Negócio**:
- Informações de preços são consistentes
- Variantes sem estoque são indicadas
- Histórico de preços pode ser exibido

---

## 🔗 Integrações

### API Endpoints
- `POST /api/v1/products` - Criar produto
- `GET /api/v1/products` - Listar produtos
- `GET /api/v1/products/:id` - Detalhes do produto
- `PUT /api/v1/products/:id` - Atualizar produto
- `POST /api/v1/products/:id/variants` - Adicionar variante
- `PUT /api/v1/variants/:id/inventory` - Atualizar estoque

### Domain Events
- `ProductCreated` - Produto criado
- `ProductUpdated` - Produto atualizado
- `ProductActivated` - Produto ativado
- `InventoryUpdated` - Estoque atualizado

---

## 📝 Observações

- Todos os casos de uso devem respeitar as regras definidas nos ADRs
- Interface deve ser responsiva e acessível
- Validações devem ocorrer tanto no frontend quanto no backend
- Logs devem ser registrados para auditoria
