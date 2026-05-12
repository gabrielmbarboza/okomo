# 🎟️ Casos de Uso - Promotions

## 🎯 Objetivo

Documentar os principais fluxos de gestão de promoções e cupons, incluindo criação, validação, aplicação e regras de negócio.

---

## 📋 Casos de Uso

### 1. Gestão de Promoções

#### UC-PROM-001: Criar Promoção
**Descrição**: Seller cria uma nova campanha promocional no sistema.

**Atores**: Seller

**Pré-condições**:
- Seller autenticado
- Permissão para gerenciar promoções

**Fluxo Principal**:
1. Seller acessa painel de promoções
2. Clica em "Nova Promoção"
3. Preenche formulário com dados:
   - Nome da promoção
   - Descrição
   - Tipo (desconto, frete grátis, etc.)
   - Data de início e fim
   - Regras de aplicação
4. Sistema valida informações
5. Promoção é criada com status "draft"
6. Seller pode configurar regras específicas
7. Promoção é ativada

**Fluxos Alternativos**:
- Promoção duplicada → Sugerir edição
- Dados inválidos → Exibir erros específicos

**Pós-condições**:
- Promoção ativa no sistema
- Notificação de sucesso
- Aplicação automática em produtos selecionados

---

### 2. Gestão de Cupons

#### UC-PROM-002: Criar Cupom
**Descrição**: Seller cria um novo cupom de desconto.

**Atores**: Seller

**Pré-condições**:
- Promoção existente e ativa
- Permissão para gerenciar cupons

**Fluxo Principal**:
1. Seller seleciona promoção ativa
2. Clica em "Gerar Cupons"
3. Define configurações:
   - Código único
   - Quantidade de cupons
   - Valor de desconto
   - Restrições de uso
4. Sistema gera códigos únicos
5. Cupons são criados com status "available"
6. Seller pode distribuir códigos

**Regras de Negócio**:
- Código deve ser único globalmente
- Cupons não podem ser gerados após expiração
- Quantidade limitada por promoção

---

### 3. Validação de Cupom

#### UC-PROM-003: Validar Cupom
**Descrição**: Buyer ou sistema valida um cupom antes da aplicação.

**Atores**: Buyer, Sistema

**Pré-condições**:
- Código do cupom informado
- Cupom existe no sistema

**Fluxo Principal**:
1. Sistema busca cupom pelo código
2. Verifica:
   - Validade
   - Status (available, used, expired)
   - Restrições de aplicação
3. Retorna resultado da validação:
   - Válido: detalhes do cupom
   - Inválido: motivo específico

**Regras de Negócio**:
- Cupom usado não pode ser reaplicado
- Cupom expirado é automaticamente invalidado
- Validação deve ser idempotente

---

### 4. Aplicação de Cupom

#### UC-PROM-004: Aplicar Cupom no Checkout
**Descrição**: Buyer aplica um cupom durante o processo de checkout.

**Atores**: Buyer, Checkout Service

**Pré-condições**:
- Checkout em andamento
- Cupom válido e disponível

**Fluxo Principal**:
1. Buyer informa código do cupom
2. Checkout Service valida cupom
3. Desconto é calculado e aplicado ao total
4. Novo total é exibido
5. Cupom é marcado como "used"
6. Estoque é atualizado

**Regras de Negócio**:
- Apenas um cupom por pedido
- Cupons não cumulativos (regra de negócio)
- Aplicação deve ser atômica

---

### 5. Relatórios de Promoções

#### UC-PROM-005: Relatório de Desempenho
**Descrição**: Seller visualiza métricas de desempenho das promoções.

**Atores**: Seller

**Pré-condições**:
- Permissão para relatórios

**Fluxo Principal**:
1. Seller acessa painel de relatórios
2. Seleciona período e tipo de promoção
3. Sistema exibe métricas:
   - Número de cupons gerados
   - Taxa de utilização
   - Valor total de descontos concedidos
   - ROI da campanha
4. Relatório pode ser exportado

**Regras de Negócio**:
- Dados agregados para proteção de privacidade
- Período mínimo para relatórios significativos

---

## 🔗 Integrações

### API Endpoints
- `POST /api/v1/promotions` - Criar promoção
- `POST /api/v1/promotions/:id/coupons` - Gerar cupons
- `GET /api/v1/coupons/:code/validate` - Validar cupom
- `GET /api/v1/promotions/:id/report` - Relatório de desempenho

### Domain Events
- `PromotionCreated` - Promoção criada
- `PromotionActivated` - Promoção ativada
- `CouponGenerated` - Cupons gerados
- `CouponApplied` - Cupom aplicado
- `PromotionExpired` - Promoção expirada

### Serviços Envolvidos
- `PromotionService` - Lógica de negócio
- `CouponService` - Validação e geração
- `ValidationService` - Validações
- `ReportingService` - Métricas e relatórios

---

## 📝 Observações

- Promoções devem seguir Specification Pattern
- Cupons devem ter controle de quantidade
- Aplicação deve ser idempotente
- Logs detalhados para auditoria
- Interface responsiva para mobile
- Cache de promoções para performance
