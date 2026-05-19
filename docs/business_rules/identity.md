# Business Rules — Identity

> Contexto responsavel por usuarios, autenticacao, autorizacao, roles e habilitacao de sellers.

## Regras de Conta

| ID | Regra |
| --- | --- |
| BR-ID-001 | Todo `User` novo deve iniciar com status `pending_confirmation`. |
| BR-ID-002 | Um `User` em `pending_confirmation` nao pode autenticar nem executar operacoes transacionais. |
| BR-ID-003 | Confirmacao de e-mail exige token valido, nao expirado, nao utilizado e associado ao `User`. |
| BR-ID-004 | Tokens de confirmacao de e-mail expiram em 24 horas. |
| BR-ID-005 | Apos confirmar e-mail, o `User` deve mudar para `active` e receber automaticamente a role `buyer`. |
| BR-ID-006 | A role `buyer`, uma vez concedida por confirmacao de e-mail, nao pode ser revogada pelo fluxo comum. |
| BR-ID-007 | Um `User` nunca deve voltar para `pending_confirmation` depois de confirmado. |
| BR-ID-008 | Usuarios `blocked`, `deactivated` ou anonimizados nao podem autenticar. |
| BR-ID-009 | Bloqueios e desativacoes devem preservar historico, roles e dados necessarios para auditoria e obrigacoes legais. |
| BR-ID-010 | Credenciais invalidas devem retornar mensagem generica para nao revelar existencia de e-mail. |

## Regras de Senha e Sessao

| ID | Regra |
| --- | --- |
| BR-ID-011 | Senhas devem ser armazenadas somente como hash seguro, nunca em texto claro. |
| BR-ID-012 | Registro e reset de senha devem validar forca minima da senha. |
| BR-ID-013 | Tokens de recuperacao de senha expiram em 2 horas. |
| BR-ID-014 | Reset de senha exige token valido, nao expirado e nao utilizado. |
| BR-ID-015 | JWT de autenticacao deve conter somente dados minimos para identificacao e autorizacao. |
| BR-ID-016 | JWT deve ter expiracao curta; a politica inicial e 15 minutos. |

## Regras de Roles e Autorizacao

| ID | Regra |
| --- | --- |
| BR-ID-017 | Um `User` pode possuir multiplas roles simultaneamente. |
| BR-ID-018 | Roles devem ser concedidas e revogadas por registros auditaveis de `UserRole`. |
| BR-ID-019 | Operacoes administrativas exigem role `platform_admin`. |
| BR-ID-020 | Roles de usuarios bloqueados ou desativados permanecem registradas, mas nao produzem autorizacao efetiva. |

## Regras de SellerProfile

| ID | Regra |
| --- | --- |
| BR-ID-021 | Apenas `User` ativo e com e-mail confirmado pode solicitar habilitacao como seller. |
| BR-ID-022 | Um `User` nao pode possuir mais de um `SellerProfile` ativo ou em revisao ao mesmo tempo. |
| BR-ID-023 | Nova solicitacao de seller deve iniciar em `pending_review`. |
| BR-ID-024 | `SellerProfile` em `pending_review` nao concede role `seller` e nao permite venda. |
| BR-ID-025 | Aprovacao de seller exige documentacao valida e revisao por usuario com role `platform_admin`. |
| BR-ID-026 | Ao aprovar um seller, o sistema deve conceder role `seller` e registrar `approved_at` e revisor. |
| BR-ID-027 | Rejeicao de seller exige motivo registrado e impede nova aplicacao por 30 dias. |
| BR-ID-028 | Suspensao de seller exige motivo registrado, revoga a role `seller` e bloqueia novas vendas. |
| BR-ID-029 | Suspensao de seller nao deve cancelar automaticamente pedidos ja em andamento. |
| BR-ID-030 | Reativacao de seller exige resolucao registrada e nova concessao auditavel da role `seller`. |

## Eventos Esperados

* `UserRegistered`
* `UserEmailConfirmed`
* `UserAuthenticated`
* `PasswordRecoveryRequested`
* `PasswordResetCompleted`
* `RoleGranted`
* `RoleRevoked`
* `SellerApplicationSubmitted`
* `SellerApproved`
* `SellerRejected`
* `SellerSuspended`
* `SellerReactivated`
