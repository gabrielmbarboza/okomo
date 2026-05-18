# Privacidade e LGPD — Okomo

> **Status:** Draft  
> **Responsável:** Engenharia de Software  
> **Última Atualização:** 2026-05-17

Este documento define a base técnica e operacional para tratar dados pessoais no Okomo em conformidade com a LGPD. Ele deve ser revisado com jurídico/DPO antes do lançamento público e sempre que novos fluxos de dados forem adicionados.

A decisão arquitetural principal está registrada na [ADR-020 — LGPD Compliance and Personal Data Governance](adr/ADR-020-lgpd-compliance-and-personal-data-governance.md).

## 1. Princípios Aplicados

* **Finalidade:** cada dado pessoal deve ter uma finalidade de produto, segurança, obrigação legal ou execução contratual.
* **Adequação:** o uso do dado deve ser compatível com a finalidade comunicada ao titular.
* **Necessidade:** coletar o mínimo necessário para cadastro, compra, venda, pagamento, entrega, suporte e prevenção a fraude.
* **Livre acesso:** titulares devem conseguir solicitar confirmação de tratamento, acesso, correção, portabilidade, exclusão ou anonimização quando cabível.
* **Segurança:** dados pessoais não devem aparecer em logs, exceções, payloads públicos ou exportações administrativas sem necessidade explícita.
* **Prevenção:** novos atributos pessoais precisam ser classificados antes de entrar no modelo.
* **Responsabilização:** decisões sobre tratamento, retenção e descarte devem ser documentadas.

## 2. Inventário Inicial de Dados

| Contexto | Entidade | Dados pessoais | Sensibilidade | Finalidade | Base legal candidata |
| --- | --- | --- | --- | --- | --- |
| Identity | User | nome, e-mail, hash de senha, confirmação de e-mail, último login | pessoal comum / credencial derivada | conta, autenticação, segurança | execução de contrato, legítimo interesse, prevenção à fraude |
| Identity | User consent markers | aceite de termos, aceite de política de privacidade, versão do consentimento, IP e User-Agent quando usados | pessoal comum / metadado de auditoria | prova de consentimento, transparência e compliance | consentimento, execução de contrato, legítimo interesse |
| Identity | SellerProfile | CPF/CNPJ/MEI, nome legal, e-mail, telefone, endereço comercial | documento e contato | habilitação de vendedor, suporte, compliance fiscal e antifraude | execução de contrato, obrigação legal/regulatória, legítimo interesse |
| Orders | Order | user_id, status, valores, cupom | identificador indireto | compra, histórico, suporte, obrigações fiscais | execução de contrato, obrigação legal |
| Promotions | CouponRedemption | user_id, order_id, data de uso | identificador indireto | aplicação de benefício e prevenção de abuso | execução de contrato, legítimo interesse |

Quando um novo dado pessoal for adicionado, atualize esta tabela no mesmo PR.

## 3. Classificação Técnica

Campos marcados como sensíveis em entidades de domínio devem usar `sensitive_attributes`, para que serialização segura e `inspect` redijam valores por padrão:

```ruby
sensitive_attributes :email, :document_number, :commercial_address
```

Regras:

* nunca retornar `password_digest`, tokens, documentos, telefones, endereços ou dados de pagamento em APIs públicas;
* usar `to_h(redact: true)` ou `as_json` para payloads de log e debug;
* adicionar filtros em `config/initializers/filter_parameter_logging.rb` para todo novo parâmetro pessoal ou secreto;
* criptografar em repouso dados de documento, telefone, endereço e dados equivalentes antes de persistir;
* preferir identificadores internos opacos (`UUID`) a dados pessoais em eventos de domínio.

## 4. Direitos do Titular

O Okomo deve oferecer processo autenticado para:

* confirmar existência de tratamento;
* acessar dados pessoais mantidos na conta;
* corrigir dados incompletos, inexatos ou desatualizados;
* solicitar anonimização, bloqueio ou eliminação de dados desnecessários, excessivos ou tratados em desconformidade;
* solicitar portabilidade quando aplicável;
* obter informação sobre compartilhamento com operadores e parceiros;
* revogar consentimento quando a base legal for consentimento.

Antes de automatizar exclusão, a aplicação deve verificar retenções obrigatórias, por exemplo pedidos, pagamentos, notas fiscais, chargebacks, prevenção a fraude e disputas.

## 4.1. Consentimento

O cadastro deve registrar, no mínimo:

* aceite dos Termos de Uso;
* aceite da Política de Privacidade;
* timestamp dos aceites;
* versão dos documentos aceitos;
* IP e User-Agent somente quando necessários para prova, segurança ou auditoria.

Mudanças materiais nos documentos devem gerar nova versão de consentimento e exigir novo aceite quando a base legal depender de consentimento ou quando a transparência com o titular exigir revalidação.

## 4.2. Anonimização de Conta

Anonimização não é exclusão física. O fluxo deve:

* preservar `user_id` quando necessário para integridade de pedidos, pagamentos, auditoria e obrigações legais;
* remover ou substituir nome, e-mail, telefone, endereço e documentos quando a retenção legal permitir;
* invalidar sessões, tokens e credenciais;
* marcar `anonymized_at`;
* publicar `AccountAnonymized`;
* impedir uso futuro da conta anonimizada para login.

## 5. Retenção e Descarte

| Dado | Retenção mínima sugerida | Descarte |
| --- | --- | --- |
| Conta de usuário | enquanto a conta estiver ativa | anonimizar nome/e-mail após encerramento, preservando chaves técnicas necessárias |
| Credenciais e tokens | menor prazo operacional possível | invalidar tokens usados/expirados; nunca armazenar senha em texto claro |
| Dados fiscais e pedidos | conforme obrigação legal/fiscal aplicável | preservar registros obrigatórios e anonimizar campos não necessários |
| Logs de segurança | prazo definido em política de segurança | remover/redigir dados pessoais; manter eventos agregados quando possível |
| SellerProfile rejeitado | prazo necessário para auditoria e prevenção a fraude | anonimizar documento, contato e endereço ao fim do prazo |

Os prazos finais precisam ser validados com jurídico/contabilidade antes da produção.

## 6. Compartilhamento e Operadores

Todo operador que receber dados pessoais deve estar registrado no inventário de fornecedores com:

* finalidade do tratamento;
* categorias de dados compartilhados;
* país/região de processamento;
* base legal;
* contrato/DPA ou cláusula equivalente;
* retenção e mecanismo de exclusão.

Operadores prováveis: provedor de e-mail, gateway de pagamento, antifraude, logística/frete, hospedagem, observabilidade e suporte.

## 7. Incidentes

Incidentes que envolvam dados pessoais devem registrar:

* data/hora de detecção;
* categoria e volume estimado de titulares afetados;
* dados envolvidos;
* sistemas e operadores envolvidos;
* contenção aplicada;
* risco aos titulares;
* decisão sobre comunicação à ANPD e aos titulares.

## 8. Checklist de PR

Antes de aprovar mudanças que toquem dados pessoais:

* [ ] o dado aparece no inventário desta página;
* [ ] a finalidade e base legal candidata estão documentadas;
* [ ] logs e exceções não expõem valores pessoais;
* [ ] APIs retornam apenas o necessário para o caso de uso;
* [ ] campos sensíveis usam `sensitive_attributes`;
* [ ] parâmetros sensíveis estão em `filter_parameter_logging`;
* [ ] há plano de retenção, anonimização ou exclusão;
* [ ] operadores externos foram documentados quando houver compartilhamento.

## 9. Referências

* Lei nº 13.709/2018 — Lei Geral de Proteção de Dados Pessoais.
* ANPD — orientações para titulares de dados: https://www.gov.br/anpd/pt-br/assuntos/titular-de-dados-1/titular-de-dados
* Portal gov.br — visão geral sobre LGPD, controlador, operador e encarregado: https://www.gov.br/int/pt-br/acesso-a-informacao/lgpd
