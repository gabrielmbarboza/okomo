# 7. Security Model (docs/security.md)

> **Status:** Draft  
> **Responsável:** Engenharia de Software  
> **Última Atualização:** 2026-05-11

Este documento define as diretrizes de segurança do Okomo, cobrindo desde o acesso à plataforma até a integridade das transações financeiras.

---

## 1. Autenticação (Authentication)

O Okomo utiliza uma abordagem híbrida para garantir que apenas usuários legítimos acessem o sistema.

### 1.1. Estratégia por Perfil
* **Sellers & Buyers:** Autenticação baseada em sessões seguras (Cookies HTTP-only e Secure) via **Devise**.
* **API Integrations:** Autenticação via **Bearers Tokens (JWT)** com tempo de expiração curto (Short-lived tokens).
* **Admin:** Autenticação multi-fator (MFA) obrigatória para acesso ao painel administrativo.

### 1.2. Requisitos de Senha
* Mínimo de 12 caracteres.
* Uso de algoritmos de hashing modernos (Argon2 ou BCrypt com alto custo de processamento).

---

## 2. Autorização (Authorization)

Utilizamos o padrão **RBAC (Role-Based Access Control)** para definir permissões, garantindo o princípio do menor privilégio.

### 2.1. Papéis (Roles)
* **System Admin:** Acesso total à infraestrutura e gestão de usuários.
* **Seller:** Acesso exclusivo aos seus produtos (`Catalog`), estoque (`Inventory`) e pedidos recebidos (`Orders`).
* **Buyer:** Acesso ao histórico de compras e perfil pessoal.

### 2.2. Isolamento de Dados (Multitenancy)
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

## 6. Logs de Auditoria (Audit Trail)

Operações críticas devem deixar rastro para análise forense:

* **Alterações de Inventário:** Quem alterou, quando e por qual motivo (Ajuste manual vs. Venda).
* **Acessos Administrativos:** Log de visualização de dados sensíveis de usuários.
* **Eventos de Segurança:** Registro de falhas de login e ativação de rate limit.

---

## 7. Conformidade (LGPD)

* **Minimização:** Coletamos apenas os dados necessários para o processamento da venda.
* **Criptografia:** Dados sensíveis (como endereços e telefones) criptografados em repouso.
* **Direito ao Esquecimento:** Rotinas para anonimização de dados de `Buyers` após o período legal de retenção fiscal.