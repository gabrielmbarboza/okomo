# State Machine — User

## Visão Geral

Este documento descreve a máquina de estados do agregado `User` no Bounded Context Identity.

O `User` passa por diferentes estados durante seu ciclo de vida na plataforma, refletindo sua capacidade de se autenticar e realizar ações.

---

## Estados

### 1. pending_confirmation

**Descrição:** Estado inicial logo após registro.

**Características:**

- Usuário foi criado mas e-mail não foi confirmado
- Não pode fazer login
- Não recebeu role `buyer`
- E-mail de confirmação foi enviado

**Transições Saem De:**

- Nenhuma (estado inicial)

**Transições Vão Para:**

- `active` (via `Confirm Email`)
- `blocked` (via admin, por suspeita de fraude)

**Permanência Típica:** 0-24h (com token de confirmação de 24h)

---

### 2. active

**Descrição:** Estado normal, usuário com e-mail confirmado e sem restrições.

**Características:**

- E-mail foi confirmado com sucesso
- Recebeu automaticamente role `buyer`
- Pode fazer login
- Pode realizar operações de comprador
- Pode solicitar para se tornar vendedor (criar SellerProfile)

**Transições Saem De:**

- `pending_confirmation` (via `Confirm Email`)
- `blocked` (via admin, reverter bloqueio)
- `deactivated` (via user ou admin, reativar conta)

**Transições Vão Para:**

- `blocked` (via admin, por violação)
- `deactivated` (via user, desativação voluntária)

**Permanência Típica:** Indefinida (normal)

---

### 3. blocked

**Descrição:** Conta bloqueada por violação de políticas.

**Características:**

- Não pode fazer login
- Não pode realizar nenhuma operação na plataforma
- Histórico e dados são preservados
- Admin pode rever e desbloquear
- Motivo do bloqueio é registrado (auditável)

**Transições Saem De:**

- `pending_confirmation` (via admin, suspeita de fraude)
- `active` (via admin, violação detectada)

**Transições Vão Para:**

- `active` (via admin, ao resolver o problema)
- `deactivated` (após revisão, se user concordar)

**Permanência Típica:** Variável (até resolução)

---

### 4. deactivated

**Descrição:** Conta desativada voluntariamente pelo user ou por inatividade.

**Características:**

- User solicitou desativação ou foi desativado por admin
- Não pode fazer login
- Não pode realizar operações
- Dados são preservados (LGPD compliance)
- Pode ser reativada em alguns casos

**Transições Saem De:**

- `active` (via user, auto-desativação)
- `active` (via admin, desativação administrativa)
- `blocked` (via admin, após resolução)

**Transições Vão Para:**

- `active` (via user ou admin, reativação)

**Permanência Típica:** Variável (dias a meses)

---

## Transições de Estado

### pending_confirmation → active

**Acionador:** Usuário confirma e-mail via link
**Caso de Uso:** Confirm Email
**Efeitos Colaterais:**

- UserRole criado para role `buyer`
- Evento `UserEmailConfirmed` publicado
- Evento `RoleGranted` publicado
- E-mail de boas-vindas enviado

**Guard Conditions:**

- Token deve ser válido
- Token não pode ter expirado
- Token não pode ter sido já utilizado

---

### pending_confirmation → blocked

**Acionador:** Admin bloqueia conta
**Caso de Uso:** Bloquear usuário suspeito
**Efeitos Colaterais:**

- Motivo do bloqueio é registrado
- Notificação interna para análise
- Evento de auditoria publicado

---

### active → blocked

**Acionador:** Admin detecta violação de políticas
**Caso de Uso:** Suspender conta por comportamento malicioso
**Efeitos Colaterais:**

- Todos os UserRoles permanecem (mas inefetivos)
- Se User era seller, SellerProfile não é suspenso automaticamente
- Notificação enviada ao user
- Ticket criado para revisão

**Guard Conditions:**

- User admin deve ter role `platform_admin`

---

### active → deactivated

**Acionador:** User solicita desativação ou admin desativa
**Caso de Uso:** User desativa sua conta voluntariamente
**Efeitos Colaterais:**

- Todos os UserRoles permanecem (mas inefetivos)
- Acesso ao sistema bloqueado
- Dados preservados
- Evento de auditoria publicado

---

### blocked → active

**Acionador:** Admin reverte bloqueio
**Caso de Uso:** Resolver problema e desbloquear conta
**Efeitos Colaterais:**

- Notificação ao user
- Acesso restaurado
- Evento de auditoria publicado

**Guard Conditions:**

- User admin deve ter role `platform_admin`

---

### deactivated → active

**Acionador:** User reativa conta ou admin reativa
**Caso de Uso:** User reativa sua conta
**Efeitos Colaterais:**

- Acesso restaurado
- UserRoles permanecem intactos
- E-mail de confirmação pode ser enviado
- Evento de auditoria publicado

---

### blocked → deactivated

**Acionador:** Admin decide converter bloqueio em desativação
**Caso de Uso:** Transição alternativa
**Efeitos Colaterais:**

- Motivo original é preservado
- Novo status de desativação criado

---

## Diagrama de Estados

```
┌──────────────────┐
│ pending_confirm- │
│    ation         │
└────────┬─────────┘
         │
    [Confirm Email]
    [Admin Blocks]
         ▼
┌──────────────────┐          [Admin Blocks]   ┌─────────┐
│     active   ◄──┼─────────────────────────────► blocked │
│              │  │                             └─────────┘
│              │  │                                 ▲
│              │  │                    [Admin Unblocks]
│              │  └────────────┐                    │
│              │               │                    │
│              │          [Self/Admin               │
│              │           Deactivate]              │
│              │               ▼                    │
│              │        ┌──────────────┐            │
│              │        │ deactivated  ┼────────────┘
│              │        └──────────────┘
│              │               │
│              │        [Reactivate]
│              │               │
│              └───────────────┘
```

---

## Validações e Invariantes

1. **Nunca Reverter para pending_confirmation:** Uma vez confirmado, nunca volta para aguardando confirmação

2. **Ativo é Transeunte:** Qualquer outro estado pode ser acionado do ativo

3. **Bloqueado é Restritivo:** Nenhuma operação é permitida

4. **Deativado Preserva Dados:** Dados nunca são deletados, apenas ocultados

5. **Role buyer Nunca Revogado:** Mesmo em estados restritivos, o role permanece atribuído

6. **Admin Sempre Necessário:** Transições administrativas requerem `platform_admin`

---

## Notas de Implementação

- Estados devem ser implementados como enums ou constantes na classe `User`
- Cada transição deve ser uma operação atômica com validações
- Eventos de domínio devem ser publicados após transições bem-sucedidas
- Auditoria deve registrar quem, quando e por que cada mudança ocorreu
- Testes devem cobrir todas as transições e validações
