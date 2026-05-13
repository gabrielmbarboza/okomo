# 7. Security Model (docs/security.md)

> **Status:** Draft  
> **Responsável:** Engenharia de Software  
> **Última Atualização:** 2026-05-11

Este documento define as diretrizes de segurança do Okomo, cobrindo desde o acesso à plataforma até a integridade das transações financeiras.

---

## 1. Autenticação (Authentication)

O Okomo utiliza uma abordagem nativa do Rails para garantir que apenas usuários legítimos acessem o sistema, conforme ADR-014.

### 1.1. Estratégia por Perfil
* **Sellers & Buyers:** Autenticação via **has_secure_password** com bcrypt para hash de senhas e **JWT** para autenticação stateless na API.
* **API Integrations:** Autenticação via **Bearers Tokens (JWT)** com tempo de expiração curto (Short-lived tokens).
* **Admin:** Autenticação multi-fator (MFA) obrigatória para acesso ao painel administrativo (evolução futura).

### 1.2. has_secure_password com bcrypt
* Utiliza o método nativo `has_secure_password` do Rails
* Hash de senhas realizado com bcrypt (cost factor configurável)
* Senhas nunca são armazenadas em texto plano
* Validação automática de senhas durante autenticação

### 1.3. JWT Stateless Authentication
* Tokens JWT para autenticação stateless na API
* Access tokens com curta duração (ex: 15 minutos)
* Payload contém user_id e email
* Assinatura com secret key armazenada em Rails.credentials
* Algoritmo HS256 para assinatura

### 1.4. Refresh Tokens (Evolução Futura)
* Refresh tokens com duração mais longa (ex: 7 dias)
* Implementação opcional para melhor experiência do usuário
* Armazenamento seguro em Redis para revogação

### 1.5. Confirmação Obrigatória de E-mail
* Todo novo usuário deve confirmar e-mail antes de acessar a plataforma
* Tokens de confirmação com expiração (ex: 24 horas)
* Role buyer atribuído automaticamente após confirmação
* Prevenção de contas falsas ou temporárias

### 1.6. Recuperação Segura de Senha
* Processo de recuperação via token seguro
* Tokens com expiração curta (ex: 1 hora)
* Tokens invalidados após uso
* Envio de e-mail com link seguro
* Auditoria de todas as tentativas de recuperação

### 1.7. Requisitos de Senha
* Mínimo de 8 caracteres
* Hash com bcrypt (cost factor configurável)
* Validação de força opcional (evolução futura)

---

## 2. Autorização (Authorization)

Utilizamos o padrão **RBAC (Role-Based Access Control)** para definir permissões, garantindo o princípio do menor privilégio.

### 2.1. Papéis (Roles)
* **System Admin:** Acesso total à infraestrutura e gestão de usuários.
* **Seller:** Acesso exclusivo aos seus produtos (`Catalog`), estoque (`Inventory`) e pedidos recebidos (`Orders`).
* **Buyer:** Acesso ao histórico de compras e perfil pessoal.

### 2.2. RBAC com buyer, seller e admin
* Implementação de Role-Based Access Control (RBAC)
* Roles armazenados como entidades separadas no Bounded Context Identity
* Um User pode possuir múltiplos roles simultaneamente
* Role buyer atribuído automaticamente após confirmação de e-mail
* Role seller exige solicitação e aprovação manual
* Role admin para gestão administrativa da plataforma
* Validação de permissões em nível de controller e serviço

### 2.3. Isolamento de Dados (Multitenancy)
Como o Okomo é um SaaS, o isolamento é crítico:
* **Scope Leaking:** Todas as queries em contextos de `Seller` devem ser escopadas pelo `seller_id` no nível do banco de dados ou via `acts_as_tenant`.
* **UUIDs:** O uso de UUIDs em todas as chaves primárias previne ataques de **ID Enumeration**, impedindo que um atacante tente acessar o pedido #1, #2, #3 sequencialmente.

---

## 3. Rate Limiting e Proteção de Recursos

Para prevenir ataques de negação de serviço (DoS) e brute force, implementamos limites em múltiplas camadas.

* **Global Rate Limit:** Máximo de 100 requisições por minuto por IP para rotas públicas de navegação.
* **Auth Throttling:** Limites rigorosos para `/login` e `/password_reset` (ex: 5 tentativas por 10 minutos por e-mail).
* **API Throttling:** Baseado no `client_id` da integração, com suporte a *bursting* controlado via Redis.

---

## 4. Prevenção contra Fraudes e Consistência Transacional

Dado o risco inerente a marketplaces, o sistema implementa defesas específicas:

### 4.1. Integridade Financeira
* **Imutabilidade de Preços:** O `OrderItem` captura um snapshot do preço no momento do checkout. Alterações posteriores no `Catalog` não afetam pedidos em processamento.
* **Re-validação de Coupon:** Cupons são re-validados a cada mudança no carrinho para evitar "exploit de soma".

### 4.2. Defesa contra Overselling e Invasão de Estoque
* **Pessimistic Locking:** Garante que dois usuários não "ganhem" o último item do estoque simultaneamente.
* **Idempotência:** Tokens de idempotência em todas as operações de reserva e liberação de estoque (`InventoryReservation`) para evitar duplicidade em retries de rede.

---

## 5. Proteções Web (OWASP Top 10)

O Rails 8 já oferece proteções nativas que são configuradas como padrão no Okomo:

* **XSS (Cross-Site Scripting):** Sanitização automática de views e uso de `Content Security Policy` (CSP).
* **CSRF (Cross-Site Request Forgery):** Verificação de tokens em todas as requisições que alteram estado (POST, PUT, DELETE).
* **SQL Injection:** Uso obrigatório de Active Record ORM ou sanitização de queries manuais.

---

## 6. Secrets e Credenciais

Secrets sensíveis são armazenados de forma segura utilizando Rails.credentials.

### 6.1. Armazenamento de Secrets
* JWT_SECRET_KEY: Chave secreta para assinatura de tokens JWT
* SMTP credentials: Credenciais para envio de e-mails
* API keys: Chaves de integrações externas
* Database credentials: Credenciais de banco de dados

### 6.2. Boas Práticas
* Secrets nunca commitados no repositório
* Uso de Rails.credentials.edit para gerenciar secrets
* Variáveis de ambiente para secrets em produção
* Rotação periódica de secrets críticos
* Acesso restrito a secrets em equipe

---

## 7. Logs de Auditoria (Audit Trail)

Operações críticas devem deixar rastro para análise forense:

* **Alterações de Inventário:** Quem alterou, quando e por qual motivo (Ajuste manual vs. Venda).
* **Acessos Administrativos:** Log de visualização de dados sensíveis de usuários.
* **Eventos de Segurança:** Registro de falhas de login e ativação de rate limit.

---

## 8. Conformidade (LGPD)

* **Minimização:** Coletamos apenas os dados necessários para o processamento da venda.
* **Criptografia:** Dados sensíveis (como endereços e telefones) criptografados em repouso.
* **Direito ao Esquecimento:** Rotinas para anonimização de dados de `Buyers` após o período legal de retenção fiscal.