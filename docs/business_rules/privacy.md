# Business Rules — Privacy e LGPD

> Regras transversais para tratamento de dados pessoais, consentimento, retencao, anonimização e compartilhamento.

## Regras de Coleta e Uso

| ID | Regra |
| --- | --- |
| BR-PRV-001 | Todo dado pessoal deve ter finalidade documentada antes de entrar no modelo. |
| BR-PRV-002 | O produto deve coletar somente dados necessarios para cadastro, compra, venda, pagamento, entrega, suporte, seguranca e obrigacoes legais. |
| BR-PRV-003 | Dados pessoais nao devem aparecer em logs, excecoes, payloads publicos ou exportacoes administrativas sem necessidade explicita. |
| BR-PRV-004 | APIs publicas devem retornar somente dados pessoais necessarios ao caso de uso. |
| BR-PRV-005 | Eventos de dominio devem preferir UUIDs e referencias internas em vez de dados pessoais. |

## Regras de Consentimento

| ID | Regra |
| --- | --- |
| BR-PRV-006 | Cadastro deve registrar aceite dos Termos de Uso e da Politica de Privacidade. |
| BR-PRV-007 | Consentimento deve registrar timestamps, versao dos documentos e metadados tecnicos proporcionais quando necessarios. |
| BR-PRV-008 | Mudanca material nos documentos pode exigir novo aceite. |
| BR-PRV-009 | Um user ativo deve possuir aceite valido dos documentos obrigatorios do produto. |

## Regras de Segurança e Retencao

| ID | Regra |
| --- | --- |
| BR-PRV-010 | `password_digest`, tokens, documentos, telefones, enderecos e dados de pagamento nao devem ser retornados por APIs publicas. |
| BR-PRV-011 | Dados pessoais sensiveis ou de maior risco devem ser criptografados em repouso quando persistidos. |
| BR-PRV-012 | Parametros pessoais e secretos devem estar cobertos por filtros de log. |
| BR-PRV-013 | Exclusao fisica de user nao e estrategia padrao quando houver pedidos, pagamentos, auditoria ou obrigacoes legais vinculadas. |
| BR-PRV-014 | Retencoes obrigatorias devem ser avaliadas antes de qualquer exclusao, anonimização ou portabilidade. |

## Regras de Direitos do Titular

| ID | Regra |
| --- | --- |
| BR-PRV-015 | Titular deve poder solicitar acesso, correcao, portabilidade, anonimização, bloqueio ou eliminacao quando cabivel. |
| BR-PRV-016 | Anonimizacao de conta deve invalidar sessoes, tokens e credenciais. |
| BR-PRV-017 | Conta anonimizada nao pode autenticar novamente. |
| BR-PRV-018 | Anonimizacao deve preservar integridade tecnica de pedidos, pagamentos e auditoria quando houver retencao legitima. |

## Regras de Operadores e Incidentes

| ID | Regra |
| --- | --- |
| BR-PRV-019 | Todo operador que receber dados pessoais deve constar no inventario de fornecedores. |
| BR-PRV-020 | Incidentes envolvendo dados pessoais devem registrar deteccao, impacto, dados envolvidos, contencao e decisao de comunicacao. |

## Eventos Esperados

* `ConsentAccepted`
* `ConsentRenewalRequested`
* `PersonalDataExportRequested`
* `PersonalDataCorrected`
* `AccountAnonymized`
