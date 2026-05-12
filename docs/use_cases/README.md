# 📘 Casos de Uso - Okomo

> **Status:** Documentação em andamento  
> **Responsável:** Engenharia de Software  
> **Última Atualização:** 2026-05-12

Este diretório contém os casos de uso organizados por bounded context, facilitando a manutenção e evolução da documentação.

---

## 🏗️ Estrutura de Diretórios

```
docs/use_cases/
├── README.md                 # Este arquivo - visão geral
├── catalog/                # Casos de uso do domínio Catalog
│   ├── README.md
│   ├── product_management.md
│   ├── inventory_management.md
│   └── catalog_browsing.md
├── checkout/               # Casos de uso do fluxo de checkout
│   ├── README.md
│   ├── checkout_flow.md
│   ├── coupon_application.md
│   └── payment_processing.md
├── orders/                 # Casos de uso do domínio Orders
│   ├── README.md
│   ├── order_management.md
│   ├── order_tracking.md
│   └── order_cancellation.md
├── payments/               # Casos de uso do domínio Payments
│   ├── README.md
│   ├── payment_processing.md
│   ├── refund_handling.md
│   └── webhook_handling.md
├── shipping/               # Casos de uso do domínio Shipping
│   ├── README.md
│   ├── shipment_creation.md
│   ├── delivery_tracking.md
│   └── return_handling.md
└── promotions/            # Casos de uso do domínio Promotions
    ├── README.md
    ├── coupon_creation.md
    ├── promotion_management.md
    └── discount_rules.md
```

---

## 🎯 Objetivo

Organizar os casos de uso por bounded context para:
- Facilitar manutenção da documentação
- Permitir evolução independente de cada domínio
- Melhorar legibilidade e localização
- Suportar desenvolvimento paralelo por equipes

---

## 📋 Padrão de Documentação

Cada caso de uso deve seguir:

### Estrutura Obrigatória
```markdown
# UC-[ID]: [Título Descritivo]

## 🎯 Objetivo
Breve descrição do propósito do caso de uso.

## 👥 Atores
Lista de atores envolvidos no fluxo.

## 📋 Pré-condições
Estado necessário do sistema antes da execução.

## 🔄 Fluxo Principal
Passo a passo do fluxo principal.

## 🔄 Fluxos Alternativos
Caminhos alternativos e tratamento de exceções.

## 🔄 Pós-condições
Estado esperado após execução bem-sucedida.

## 📊 Regras de Negócio
Regras específicas que devem ser seguidas.

## 🔗 Integrações
Endpoints de API, serviços e eventos envolvidos.

## 📝 Observações
Notas importantes sobre implementação e limitações.
```

### Identificação
- **UC-[ID]**: Identificador único
- **Título**: Nome descritivo e único
- **Prioridade**: Alta, Média ou Baixa

### Versionamento
- Cada mudança significativa deve incrementar versão
- Histórico de alterações mantido em changelog

---

## 🚀 Como Criar Novo Caso de Uso

1. **Identificar bounded context** correspondente
2. **Verificar se já existe** caso de uso similar
3. **Criar arquivo** seguindo estrutura padrão
4. **Definir ID único** following a sequência existente
5. **Preencher todas as seções** obrigatórias
6. **Revisar consistência** com outros documentos
7. **Atualizar README.md** do diretório pai

---

## 📝 Melhores Práticas

- **Usar linguagem ativa** (ex: "Buyer seleciona", "Sistema valida")
- **Ser específico** em vez de genérico
- **Incluir exemplos concretos** quando possível
- **Mapear exceções** e casos de borda
- **Definir critérios de sucesso** claros
- **Referenciar ADRs** relevantes
- **Manter sincronia** com documentação técnica

---

## 🔗 Referências

- [**Domain Model**](../domain.md) - Entidades e relacionamentos
- [**Domain Events**](../domain_events.md) - Eventos entre contextos
- [**State Machines**](../state_machines/) - Estados e transições
- [**API Documentation**](../api/) - Endpoints disponíveis
