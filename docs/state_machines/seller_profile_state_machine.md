# State Machine — SellerProfile

## Visão Geral

Este documento descreve a máquina de estados do agregado `SellerProfile` no Bounded Context Identity.

O `SellerProfile` representa o status de aplicação e aprovação de um vendedor na plataforma, incluindo o ciclo de moderação e suspensões.

---

## Estados

### 1. pending_review

**Descrição:** Estado inicial após submissão de aplicação de vendedor.

**Características:**

- Usuário submeteu aplicação para se tornar vendedor
- Aguardando revisão por moderador/admin
- User ainda não possui role `seller`
- Não pode criar produtos ou vender
- Documentos e informações estão sendo analisados

**Transições Saem De:**

- Nenhuma (estado inicial)

**Transições Vão Para:**

- `approved` (via `Approve Seller`)
- `rejected` (via `Reject Seller`)

**Permanência Típica:** 3-7 dias (SLA esperado)

---

### 2. approved

**Descrição:** Aplicação aprovada, autorizado a vender.

**Características:**

- Documentação validada com sucesso
- User recebeu role `seller`
- Pode criar produtos e listar no marketplace
- Pode fazer vendas
- Está sujeito a auditorias periódicas
- Pode ser suspenso se violar políticas

**Transições Saem De:**

- `pending_review` (via `Approve Seller`)
- `suspended` (via `Reactivate Seller`)

**Transições Vão Para:**

- `suspended` (via `Suspend Seller`)
- Sem transição direta para `rejected` no fluxo padrão

**Permanência Típica:** Indefinida (normal)

---

### 3. rejected

**Descrição:** Aplicação rejeitada, não autorizado a vender.

**Características:**

- Documentação não atendeu requisitos
- Motivo da rejeição foi comunicado ao user
- User não recebeu role `seller`
- Não pode vender na plataforma
- Pode reaplicar após 30 dias
- Dados são preservados para referência

**Transições Saem De:**

- `pending_review` (via `Reject Seller`)
- `approved` (em casos excepcionais, via admin revisão)

**Transições Vão Para:**

- `pending_review` (via nova aplicação, após 30 dias)

**Permanência Típica:** Mínimo 30 dias antes de reaplicar

---

### 4. suspended

**Descrição:** Suspensão temporária após comportamento indevido.

**Características:**

- Vendedor violou políticas ou há problemas detectados
- Role `seller` foi revogado automaticamente
- Não pode criar/editar produtos
- Produtos existentes são desativados automaticamente
- Vendas em andamento continuam, mas sem novas
- Pode ser reativado após resolução do problema
- Motivo é registrado para auditoria

**Transições Saem De:**

- `approved` (via `Suspend Seller`)

**Transições Vão Para:**

- `approved` (via `Reactivate Seller`)
- Sem transição direta para `rejected` no fluxo padrão

**Permanência Típica:** Variável (dias a semanas)

---

## Transições de Estado

### pending_review → approved

**Acionador:** Admin/Moderador aprova aplicação
**Caso de Uso:** Approve Seller
**Efeitos Colaterais:**

- UserRole criado: user recebe role `seller`
- `approved_at` preenchido com timestamp
- `reviewed_by_user_id` registra o User com role `platform_admin` que aprovou
- Evento `SellerApproved` publicado
- E-mail de aprovação enviado ao user
- Índice de busca do seller é atualizado

**Guard Conditions:**

- Admin deve ter role `platform_admin`
- SellerProfile deve estar em `pending_review`
- Documentos devem ter passado validação

**Pré-requisitos de Validação:**

- Document_number formato válido e único
- Legal_name preenchido
- Contact_email e contact_phone válidos
- Commercial_address completo

---

### pending_review → rejected

**Acionador:** Admin/Moderador rejeita aplicação
**Caso de Uso:** Reject Seller
**Efeitos Colaterais:**

- `rejected_at` preenchido com timestamp
- `reviewed_by_user_id` registra o User com role `platform_admin` que rejeitou
- `rejection_reason` preenchido com motivo
- Evento `SellerRejected` publicado
- E-mail de rejeição enviado com motivo
- User pode reaplicar após 30 dias

**Guard Conditions:**

- Admin deve ter role `platform_admin`
- SellerProfile deve estar em `pending_review`
- `rejection_reason` é obrigatório

**Razões Típicas de Rejeição:**

- Documento inválido ou vencido
- Endereço não corresponde ao documento
- Informações comerciais incompletas
- Verificação manual falhou
- Suspeita de fraude

---

### approved → suspended

**Acionador:** Admin detecta violação ou problema
**Caso de Uso:** Suspend Seller
**Efeitos Colaterais:**

- `suspended_at` preenchido com timestamp
- `suspension_reason` registra motivo
- UserRole `seller` é revogado (com `revoked_at`)
- Todos os produtos do seller são desativados
- Pedidos existentes continuam, novas vendas bloqueadas
- Evento `SellerSuspended` publicado
- E-mail de suspensão enviado com motivo
- Ticket de revisão criado automaticamente

**Guard Conditions:**

- Admin deve ter role `platform_admin`
- SellerProfile deve estar em `approved`
- `suspension_reason` é obrigatório

**Razões Típicas de Suspensão:**

- Vendas fraudulentas
- Produtos counterfeit
- Violação de política de comunicação
- Não conformidade com SLA de entrega
- Reclamações excessivas de clientes
- Falta de resposta a investigações

---

### suspended → approved

**Acionador:** Admin resolve problema e reativa seller
**Caso de Uso:** Reactivate Seller
**Efeitos Colaterais:**

- `suspended_at` e `suspension_reason` são limpas
- UserRole `seller` é restaurado (novo granted_at)
- Todos os produtos do seller são reativados
- Evento `SellerReactivated` publicado
- E-mail de reativação enviado ao user
- Ticket de revisão é fechado

**Guard Conditions:**

- Admin deve ter role `platform_admin`
- SellerProfile deve estar em `suspended`
- Motivo da resolução pode ser registrado em um campo de nota

---

### rejected → pending_review

**Acionador:** User reaplicar após período de espera
**Caso de Uso:** Request Seller Application (novo)
**Efeitos Colaterais:**

- Novo SellerProfile é criado (ou re-ativado?)
- `status` volta para `pending_review`
- `requested_at` é atualizado
- Evento `SellerApplicationSubmitted` publicado
- Contador de tentativas é incrementado (auditoria)

**Guard Conditions:**

- Mínimo 30 dias devem ter passado desde rejeição
- Documentação deve ser resubmetida

---

### Transições Fora do Fluxo Padrão

Transições como `approved → rejected` ou `suspended → rejected` não fazem parte
do desenho inicial do Identity domain. Caso sejam necessárias no futuro,
devem ser introduzidas por nova decisão arquitetônica e evento de domínio
explícito.

---

## Diagrama de Estados

```
┌──────────────────┐
│ pending_review   │
└────────┬─────────┘
         │
  [Approve]┃[Reject]
         │ ┃ │
         ▼ ┃ ▼
    ┌────────────┐        ┌─────────┐
    │  approved  │        │ rejected │
    │  (active)  │        │          │
    │            │        └─────────┘
    │            │            ▲
    │            │            │
    │      [Suspend]   [Reapply after
    │            │      30 days]
    │            ▼        │
    │        ┌─────────┐  │
    │        │suspended├──┘
    │        └─────────┘
    │            │
    │    [Reactivate]
    │            │
    └────────────┘


Legend:
[Approve] = Approve Seller operation
[Reject] = Reject Seller operation
[Suspend] = Suspend Seller operation
[Reactivate] = Reactivate Seller operation
```

---

## Validações e Invariantes

1. **Ciclo de Vida Unidirecional:** Nunca volta diretamente (exceto suspended↔approved e rejected→pending_review após espera)

2. **Auditorias Preservadas:** Cada aprovação, rejeição ou suspensão preserva data, admin e razão

3. **Role `seller` Sincronizado:** Status e presença de role `seller` no User devem estar sempre sincronizados

4. **Documentação Exigida:** Mudanças de status requerem informações completas

5. **Período de Espera:** Rejeições requerem aguardar 30 dias antes de reaplicar

6. **Admin Necessário:** Todas as transições requerem ação explicit de admin (exceto reaplicação)

7. **Reversibilidade Limitada:** Apenas suspended→approved é reversível sem período de espera

---

## Sincronização com User

`SellerProfile` está intimamente ligado ao User associado:

| SellerProfile Status | User Action | Resultado |
|---------------------|-----------|-----------|
| pending_review | Tentar vender | Bloqueado |
| approved | Vender | Permitido |
| rejected | Aplicar novamente | Criar novo SellerProfile |
| suspended | Tentar vender | Bloqueado |

Role `seller` do User deve estar sincronizado:

```ruby
# Whenever SellerProfile transitions:
approved: "seller" role deve estar active
suspended: "seller" role deve estar revoked
rejected: "seller" role não deve existir
```

---

## Notas de Implementação

- Estados devem ser implementados como constantes: `PENDING_REVIEW`, `APPROVED`, `REJECTED`, `SUSPENDED`
- Nesta fase, as entidades são POROs puros; transações de banco pertencem a uma fase futura
- Auditoria deve registrar cada mudança com admin_id, timestamp, razão
- Eventos de domínio devem ser publicados de forma confiável
- Testes devem cobrir todas as transições e validações
- Considerar usar gem `aasm` para state machine complexas
- Documentação de dados sensíveis (document_number) deve ser criptografada em repouso

---

## Roadmap Futuro

- [ ] Implementar state machine com validações no modelo
- [ ] Webhooks para notificar sistemas externos (Webhook Gateway)
- [ ] Dashboard de moderação com workflow visual
- [ ] Appeals process para rejeições e suspensões
- [ ] Scoring de seller baseado em comportamento
- [ ] Verificação de documento automatizada (OCR + APIs)
