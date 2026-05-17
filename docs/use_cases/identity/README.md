# Identity — Casos de Uso

## Visão Geral

Este documento descreve todos os casos de uso do Bounded Context **Identity**, responsável por gerenciar usuários, autenticação, autorização e papéis de negócio na plataforma Okomo.

Os casos de uso cobrem:

- Registro e autenticação de usuários
- Gerenciamento de e-mail
- Recuperação de senha
- Gerenciamento de papéis (roles)
- Aplicação e aprovação de vendedores

---

# Casos de Uso Principais

## 1. Register User

**Ator:** Usuário anônimo
**Pré-condição:** Usuário deseja criar uma conta
**Pós-condição:** User criado com status `pending_confirmation` e e-mail de confirmação enviado

**Fluxo Principal:**

1. Usuário acessa tela de registro
2. Insere e-mail e senha
3. Sistema valida:
   - Formato de e-mail
   - Unicidade de e-mail (já existe?)
   - Força da senha (mínimo 8 caracteres, complexidade)
4. Sistema cria User com:
   - `status = pending_confirmation`
   - `password_digest` (bcrypt hash)
   - `email_confirmed_at = null`
5. Sistema gera token seguro de confirmação (SHA256, expiração 24h)
6. Sistema envia e-mail com link de confirmação
7. Publica evento `UserRegistered`
8. Retorna mensagem de sucesso: "Confira seu e-mail"

**Fluxo Alternativo — E-mail Já Existe:**

- Sistema retorna erro: "E-mail já registrado"
- Sugestiona: "Faça login" ou "Recuperar senha"

**Fluxo Alternativo — Senha Fraca:**

- Sistema retorna erro indicando requisitos não atendidos

---

## 2. Confirm Email

**Ator:** Usuário registrado
**Pré-condição:** User existe com `email_confirmed_at = null`, token de confirmação é válido
**Pós-condição:** User confirma e-mail, role `buyer` atribuído automaticamente

**Fluxo Principal:**

1. Usuário clica no link de confirmação do e-mail
2. Link contém token criptografado
3. Sistema valida token:
   - Existe?
   - Expirou? (>24h)
   - Já foi utilizado?
   - Pertence a um User?
4. Se válido:
   - Atualiza User: `email_confirmed_at = now`, `status = active`
   - Cria automaticamente UserRole com `buyer` role
   - Marca token como `used_at = now`
   - Publica evento `UserEmailConfirmed`
5. Retorna mensagem: "E-mail confirmado com sucesso! Bem-vindo!"
6. Redireciona para tela de login ou dashboard

**Fluxo Alternativo — Token Expirado:**

- Sistema retorna erro: "Link expirado"
- Oferece opção: "Reenviar e-mail de confirmação"

**Fluxo Alternativo — Token Inválido:**

- Sistema retorna erro: "Link inválido"

**Fluxo Alternativo — Token Já Utilizado:**

- Sistema retorna erro: "Link já foi utilizado"

---

## 3. Authenticate User

**Ator:** Usuário registrado e com e-mail confirmado
**Pré-condição:** User com `status = active` e e-mail confirmado
**Pós-condição:** JWT token gerado e retornado

**Fluxo Principal:**

1. Usuário acessa tela de login
2. Insere e-mail e senha
3. Sistema valida credenciais:
   - E-mail existe?
   - Password_digest corresponde? (bcrypt.compare)
4. Sistema valida status:
   - User não está bloqueado?
   - User não está deativado?
   - E-mail foi confirmado?
5. Se válido:
   - Carrega roles do usuário (via UserRole ativo)
   - Atualiza `last_login_at = now`
   - Gera JWT token com payload: { user_id, email, roles, exp: now + 15min }
   - Publica evento `UserAuthenticated`
6. Retorna token + informações básicas (user_id, email, roles)

**Fluxo Alternativo — E-mail Não Existe:**

- Sistema retorna erro genérico: "Credenciais inválidas"
- (Não revela se e-mail existe por razões de segurança)

**Fluxo Alternativo — Senha Incorreta:**

- Sistema retorna erro genérico: "Credenciais inválidas"

**Fluxo Alternativo — E-mail Não Confirmado:**

- Sistema retorna erro específico: "Confirme seu e-mail antes de fazer login"
- Oferece opção: "Reenviar e-mail de confirmação"

**Fluxo Alternativo — User Bloqueado:**

- Sistema retorna erro: "Sua conta foi bloqueada"
- Sugestiona: "Contate suporte"

---

## 4. Request Password Recovery

**Ator:** Usuário que esqueceu a senha
**Pré-condição:** User existe
**Pós-condição:** Token de recuperação gerado e e-mail enviado

**Fluxo Principal:**

1. Usuário clica "Esqueci minha senha"
2. Insere e-mail
3. Sistema valida:
   - E-mail existe?
4. Se existir:
   - Gera token seguro de recuperação (SHA256, expiração 2h)
   - Envia e-mail com link contendo token
   - Publica evento `PasswordRecoveryRequested`
5. Retorna mensagem: "Se o e-mail existe, enviaremos instruções" (mensagem genérica por segurança)

**Fluxo Alternativo — E-mail Não Existe:**

- Retorna mesma mensagem genérica (não revela)

---

## 5. Reset Password

**Ator:** Usuário com token de recuperação válido
**Pré-condição:** Token de recuperação válido e User existe
**Pós-condição:** Senha atualizada, token invalidado

**Fluxo Principal:**

1. Usuário clica no link do e-mail de recuperação
2. Link contém token criptografado
3. Sistema valida token:
   - Existe?
   - Expirou? (>2h)
   - Já foi utilizado?
4. Se válido, apresenta form para nova senha
5. Usuário insere nova senha
6. Sistema valida senha (força, complexidade)
7. Se válida:
   - Atualiza User: `password_digest = bcrypt(nova_senha)`
   - Marca token como `used_at = now`
   - Publica evento `PasswordResetCompleted`
8. Retorna mensagem: "Senha alterada com sucesso!"
9. Redireciona para tela de login

**Fluxo Alternativo — Token Expirado:**

- Sistema retorna erro: "Link expirado"

**Fluxo Alternativo — Senha Fraca:**

- Sistema valida e retorna erro com requisitos

---

## 6. Request Seller Application

**Ator:** User que deseja se tornar vendedor
**Pré-condição:** User com e-mail confirmado e status `active`
**Pós-condição:** SellerProfile criado com status `pending_review`

**Fluxo Principal:**

1. User acessa "Become a Seller" ou similar
2. Sistema apresenta form com campos obrigatórios:
   - Nome da Loja (display_name)
   - Descrição da Loja
   - Tipo de Documento (CPF/CNPJ/MEI)
   - Número do Documento
   - Nome Legal/Razão Social
   - E-mail Comercial
   - Telefone de Contato
   - Endereço Comercial (rua, número, complemento, cidade, estado, CEP)
3. User preenchea form
4. Sistema valida:
   - User não está bloqueado ou deativado?
   - User ainda não possui SellerProfile?
   - Documento tem formato válido?
   - Todos os campos obrigatórios preenchidos?
5. Se válido:
   - Cria SellerProfile com:
     - `status = pending_review`
     - `requested_at = now`
     - Dados criptografados (document_number) em repouso
   - Publica evento `SellerApplicationSubmitted`
6. Retorna mensagem: "Aplicação enviada! Analisaremos em 3-5 dias"
7. User recebe e-mail de confirmação de recebimento

**Alias de Linguagem Ubíqua:** Este caso de uso também é referido como `Apply for Seller`.

**Fluxo Alternativo — User Já é Seller:**

- Sistema retorna erro: "Você já possui uma aplicação de vendedor"

**Fluxo Alternativo — Documento Inválido:**

- Sistema retorna erro específico indicando qual campo é inválido

---

## 7. Approve Seller

**Ator:** Administrador ou moderador com role `platform_admin`
**Pré-condição:** SellerProfile com status `pending_review`
**Pós-condição:** SellerProfile aprovado, role `seller` concedido

**Fluxo Principal:**

1. Admin acessa dashboard de moderação
2. Visualiza lista de SellerProfiles em `pending_review`
3. Admin seleciona um SellerProfile
4. Admin revisa dados comerciais (documento, endereço, etc.)
5. Admin clica "Approve"
6. Sistema valida:
   - User admin realmente possui role `platform_admin`?
   - SellerProfile está em `pending_review`?
7. Se válido:
   - Atualiza SellerProfile:
     - `status = approved`
     - `approved_at = now`
     - `reviewed_by_user_id = current_user_id`
   - Cria UserRole: User recebe role `seller`
     - `granted_by_user_id = current_user_id`
   - Publica evento `SellerApproved`
8. Envia e-mail ao User: "Parabéns! Sua aplicação foi aprovada"
9. User agora pode criar produtos

**Fluxo Alternativo — Permissão Negada:**

- Sistema retorna erro: "Você não tem permissão"

---

## 8. Reject Seller

**Ator:** Administrador ou moderador com role `platform_admin`
**Pré-condição:** SellerProfile com status `pending_review`
**Pós-condição:** SellerProfile rejeitado

**Fluxo Principal:**

1. Admin acessa dashboard de moderação
2. Seleciona um SellerProfile em `pending_review`
3. Admin clica "Reject"
4. Admin insere motivo da rejeição (campo obrigatório)
5. Admin confirma rejeição
6. Sistema valida permissões
7. Se válido:
   - Atualiza SellerProfile:
     - `status = rejected`
     - `rejected_at = now`
     - `reviewed_by_user_id = current_user_id`
     - `rejection_reason = texto_inserido`
   - Publica evento `SellerRejected`
8. Envia e-mail ao User com motivo da rejeição
9. E-mail oferece opção: "Reaplicar em 30 dias"

---

## 9. Suspend Seller

**Ator:** Administrador ou moderador com role `platform_admin`
**Pré-condição:** SellerProfile com status `approved`
**Pós-condição:** SellerProfile suspenso, role `seller` revogado

**Fluxo Principal:**

1. Admin identifica violação de política por um Seller
2. Admin acessa SellerProfile aprovado
3. Admin clica "Suspend"
4. Admin insere motivo da suspensão (obrigatório)
5. Sistema valida permissões
6. Se válido:
   - Atualiza SellerProfile:
     - `status = suspended`
     - `suspended_at = now`
     - `suspension_reason = texto_inserido`
   - Revoga role `seller` do User (cria UserRole com revoked_at)
   - Publica evento `SellerSuspended`
7. Envia e-mail ao User: "Sua conta de vendedor foi suspensa"
8. Seller não pode mais criar/editar produtos ou fazer vendas

---

## 9.1. Revoke Seller Role

**Ator:** Administrador ou moderador com role `platform_admin`
**Pré-condição:** User possui role ativo `seller`
**Pós-condição:** Role `seller` revogado de forma auditável

**Fluxo Principal:**

1. Admin identifica que o User não deve mais vender.
2. Sistema localiza o `UserRole` ativo de `seller`.
3. Sistema valida que o role alvo não é `buyer`.
4. Sistema preenche `revoked_at`, `revoked_by_user_id` e `reason`.
5. Publica evento `RoleRevoked`.
6. Caches de autorização são invalidados.

**Observação:** No fluxo normal de moderação, esta revogação acontece junto de `Suspend Seller`.

---

## 10. Reactivate Seller

**Ator:** Administrador com role `platform_admin`
**Pré-condição:** SellerProfile com status `suspended`
**Pós-condição:** SellerProfile reativado, role `seller` restaurado

**Fluxo Principal:**

1. Admin detecta que problema foi resolvido
2. Acessa SellerProfile suspenso
3. Clica "Reactivate"
4. Sistema valida permissões
5. Se válido:
   - Atualiza SellerProfile:
     - `status = approved` (volta para aprovado)
     - Limpa `suspended_at` e `suspension_reason`
   - Restaura role `seller` do User (novo UserRole com granted_at)
   - Publica evento `SellerReactivated`
6. Envia e-mail ao User: "Sua conta de vendedor foi reativada"
7. Seller pode vender novamente

---

## 11. Promote to Platform Admin

**Ator:** Administrador com role `platform_admin`
**Pré-condição:** User existe, está confirmado e não está bloqueado
**Pós-condição:** Role `platform_admin` concedido de forma auditável

**Fluxo Principal:**

1. Admin seleciona um User elegível.
2. Sistema valida que o admin atual possui role `platform_admin`.
3. Sistema valida que o User alvo ainda não possui role ativo `platform_admin`.
4. Sistema cria `UserRole` com role `platform_admin`, `granted_at`, `granted_by_user_id` e `reason`.
5. Publica evento `RoleGranted`.
6. Caches de autorização são invalidados.

---

## 12. Revoke Platform Admin Role

**Ator:** Administrador com role `platform_admin`
**Pré-condição:** User possui role ativo `platform_admin`
**Pós-condição:** Role `platform_admin` revogado de forma auditável

**Fluxo Principal:**

1. Admin seleciona um User com role `platform_admin`.
2. Sistema valida que o admin atual possui permissão para a revogação.
3. Sistema localiza o `UserRole` ativo de `platform_admin`.
4. Sistema preenche `revoked_at`, `revoked_by_user_id` e `reason`.
5. Publica evento `RoleRevoked`.
6. Caches de autorização são invalidados.

---

# Matriz de Transições

```
User Status:
pending_confirmation → active (via Confirm Email)
active ↔ blocked (via admin)
active ↔ deactivated (via user ou admin)

SellerProfile Status:
pending_review → approved (via Approve Seller)
pending_review → rejected (via Reject Seller)
approved → suspended (via Suspend Seller)
suspended → approved (via Reactivate Seller)

Role Assignment:
- buyer: Atribuído automaticamente em Confirm Email, nunca revogado
- seller: Atribuído em Approve Seller, revogado em Suspend Seller, restaurado em Reactivate Seller
- platform_admin: Atribuído manualmente por outros admins, pode ser revogado
```

---

# Eventos Publicados

| Caso de Uso | Evento |
|-------------|--------|
| Register User | UserRegistered |
| Confirm Email | UserEmailConfirmed, RoleGranted (buyer) |
| Authenticate User | UserAuthenticated |
| Request Password Recovery | PasswordRecoveryRequested |
| Reset Password | PasswordResetCompleted |
| Request Seller Application | SellerApplicationSubmitted |
| Approve Seller | SellerApproved, RoleGranted (seller) |
| Reject Seller | SellerRejected |
| Suspend Seller | SellerSuspended, RoleRevoked (seller) |
| Reactivate Seller | SellerReactivated, RoleGranted (seller) |
| Promote to Platform Admin | RoleGranted (platform_admin) |
| Revoke Platform Admin Role | RoleRevoked (platform_admin) |

---

# Notas de Segurança

- **Tokens:** Sempre armazenados como SHA256 hash, nunca em texto plano
- **Senhas:** Sempre com bcrypt, nunca reversíveis
- **Mensagens de Erro:** Genéricas quando possível (e.g., "credenciais inválidas" vs "e-mail não existe")
- **Auditoria:** UserRole mantém trilha completa de quem concedeu/revogou
- **Criptografia em Repouso:** Dados sensíveis como document_number são criptografados

---

# Roadmap de Funcionalidades Futuras

- [ ] Autenticação OAuth (Google, GitHub)
- [ ] Two-Factor Authentication (2FA)
- [ ] Histórico de login para cada User
- [ ] Revogar todas as sessões do User (logout global)
- [ ] Verificação de documentos automática (OCR + API externas)
- [ ] Suspensão automática por inatividade
- [ ] System para report de violações
