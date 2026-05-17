# Okomo — Linguagem Ubíqua

## 🎯 Objetivo

Este documento define a linguagem ubíqua utilizada na plataforma Okomo.

O objetivo é:

* reduzir ambiguidades
* padronizar termos de negócio
* melhorar a comunicação entre desenvolvimento e negócio
* orientar decisões de modelagem de domínio
* manter consistência entre serviços, APIs e documentação

---

# 👥 Atores

## User

Conta de acesso ao sistema que representa a identidade básica de um usuário na plataforma.

Responsabilidades:

* autenticação e credenciais
* gerenciamento de status da conta
* configurações básicas de perfil
* vinculação com papéis de negócio (Seller/Buyer)

Observações:

* um User pode ser Seller, Buyer ou ambos
* gerenciado pelo Bounded Context Identity
* separado conceitualmente dos papéis de negócio

---

## Seller

Papel de negócio que representa a capacidade de vender no marketplace.

Responsabilidades:

* criar produtos
* gerenciar variantes
* definir preços
* gerenciar estoque
* criar cupons e promoções
* configurar estratégias de frete
* gerenciar dados fiscais (CNPJ/MEI)
* configurar informações comerciais

Observações:

* um Seller está vinculado a um User
* pode possuir uma ou múltiplas Stores
* espera-se que o Seller possua registro legal válido (MEI/CNPJ)
* gerenciado pelo Bounded Context Identity

---

## Buyer

Papel de negócio que representa a capacidade de comprar na plataforma.

Responsabilidades:

* navegar pelo catálogo
* adicionar itens ao carrinho
* criar pedidos
* realizar checkout
* concluir pagamento
* gerenciar histórico de pedidos
* configurar preferências de compra
* gerenciar endereços de entrega

Observações:

* um Buyer está vinculado a um User
* pode ter histórico e preferências específicas
* gerenciado pelo Bounded Context Identity

---

## Role

Permissão atribuída ao usuário que define suas capacidades na plataforma.

`Role` representa um catálogo global de permissões que podem ser concedidas aos usuários.

Possíveis roles:

* `buyer` - Permissão para realizar compras na plataforma
* `seller` - Permissão para criar produtos e vender na plataforma
* `platform_admin` - Permissão para gerenciar a plataforma, moderar vendedores e administrar sistema

Observações:

* um User pode possuir múltiplos roles simultaneamente
* todo User com e-mail confirmado recebe automaticamente o role `buyer`
* `buyer` é o role fundamental e não pode ser revogado após atribuição
* `seller` é um role adicional que exige solicitação e aprovação via `SellerProfile`
* `platform_admin` é atribuído apenas por administradores do sistema
* gerenciado pelo Bounded Context Identity

---

## buyer

Role fundacional atribuído automaticamente a todo `User` após confirmação de e-mail.

Responsabilidades:

* permitir compras na plataforma
* permitir criação de pedidos e checkout
* representar a capacidade mínima de participação de um usuário confirmado

Observações:

* `buyer` não pode ser revogado
* um `User` em `blocked` ou `deactivated` mantém o histórico do role, mas não pode operar na plataforma
* a atribuição é registrada por `UserRole`

---

## seller

Role adicional que concede capacidade de vender na plataforma.

Responsabilidades:

* criar e gerenciar produtos
* gerenciar variantes, preços e estoque
* operar lojas e vendas após aprovação

Observações:

* depende de `SellerProfile` aprovado
* pode ser revogado quando o vendedor é suspenso
* cada concessão ou revogação é registrada por `UserRole`

---

## platform_admin

Role administrativo usado para moderação e gestão da plataforma.

Responsabilidades:

* aprovar ou rejeitar `SellerProfile`
* suspender vendedores
* conceder ou revogar roles adicionais
* executar operações administrativas sensíveis

Observações:

* deve ser atribuído apenas por fluxo administrativo explícito
* pode ser revogado
* todas as mudanças devem permanecer auditáveis em `UserRole`

---

## UserRole

Representa a atribuição de um `Role` a um `User` em um ponto específico no tempo.

Responsabilidades:

* registrar quando um role foi concedido a um usuário
* registrar quando um role foi revogado de um usuário
* manter histórico completo e auditável de concessões e revogações
* rastrear qual administrador realizou a operação

Observações:

* cada `UserRole` preserva a data e hora de concessão e revogação
* não é possível revogar o role `buyer` após sua atribuição
* `UserRole` fornece trilha de auditoria completa
* gerenciado pelo Bounded Context Identity

---

## SellerProfile

Perfil contendo dados cadastrais e status de moderação do vendedor.

Responsabilidades:

* armazenar informações fiscais (CNPJ/MEI)
* armazenar informações comerciais (nome da loja, descrição, contatos)
* armazenar dados de endereço comercial
* controlar status de aprovação de vendedor
* registrar datas de solicitação, aprovação e suspensão

Observações:

* vinculado a um `User` via relacionamento um-para-um (opcional)
* passa por processo de moderação antes da aprovação
* um `SellerProfile` nunca é excluído, apenas suspenso ou bloqueado
* gerenciado pelo Bounded Context Identity
* criado quando um usuário solicita permissão de vendedor

---

# 🔐 Estados do Usuário (User Status)

## pending_confirmation

Estado transitório do `User` logo após o registro.

Características:

* usuário já foi criado mas e-mail não foi confirmado
* usuário não pode realizar compras (não possui role `buyer`)
* usuário recebe e-mail de confirmação com link seguro
* transição automática para `active` após confirmação de e-mail

---

## active

Estado normal de um `User` com e-mail confirmado e sem restrições.

Características:

* e-mail foi confirmado
* automaticamente recebeu role `buyer`
* pode realizar compras e outras operações permitidas por seus roles
* estado padrão esperado

---

## blocked

Estado de um `User` que foi bloqueado por violação de políticas.

Características:

* não pode fazer login
* não pode realizar ações na plataforma
* imposto por administradores do sistema
* pode ser revertido manualmente

---

## deactivated

Estado de um `User` que desativou sua conta voluntariamente ou por inatividade prolongada.

Características:

* conta desativada pelo próprio usuário ou por administrador
* pode ser reativada em alguns casos
* histórico de dados é preservado
* pode estar associado a retenção de dados em conformidade com LGPD

---

# 🛍️ Estados do Perfil de Vendedor (SellerProfile Status)

## pending_review

Estado inicial de um `SellerProfile` após submissão de aplicação.

Características:

* aguardando análise por administrador ou moderador
* usuário recebeu notificação de recebimento
* não pode vender enquanto estiver neste estado
* durante revisão, documentos podem ser solicitados

---

## approved

Estado de um `SellerProfile` que foi aprovado para vender.

Características:

* pode criar produtos e vender na plataforma
* role `seller` é automaticamente concedido ao `User` associado
* pode ser auditado periodicamente
* pode ser suspenso se violar políticas

---

## rejected

Estado de um `SellerProfile` que foi rejeitado na aplicação.

Características:

* usuário não pode vender na plataforma
* motivo da rejeição é comunicado ao usuário
* usuário pode reaplicar em futuro
* não há role `seller` atribuído ao `User`

---

## suspended

Estado de um `SellerProfile` que foi suspenso após aprovação.

Características:

* ocorre quando vendedor viola políticas ou há problemas
* usuário perde temporariamente a capacidade de vender
* role `seller` é revogado automaticamente
* pode ser reativado manualmente por administrador após resolução de problemas

---

## Email Confirmation

Processo de validação do endereço de e-mail do usuário.

Objetivo:

* garantir que o e-mail pertence ao usuário
* prevenir contas falsas ou temporárias
* habilitar automaticamente o role buyer

Fluxo:

1. usuário se registra
2. sistema envia e-mail de confirmação
3. usuário clica no link de confirmação
4. e-mail é marcado como confirmado
5. role buyer é atribuído automaticamente

---

## Password Recovery

Processo de redefinição de senha quando o usuário a esquece.

Fluxo:

1. usuário solicita recuperação de senha
2. sistema envia e-mail com token de recuperação
3. usuário define nova senha via link seguro
4. token é invalidado após uso
5. senha é atualizada

Observações:

* tokens têm expiração curta (ex: 1 hora)
* tokens são invalidados após uso
* gerenciado pelo Bounded Context Identity

---

## JWT Token

Token stateless utilizado para autenticação na API.

Características:

* não requer armazenamento no servidor
* contém informações do usuário no payload
* possui expiração configurável
* assinado com secret key

Observações:

* access tokens têm curta duração (ex: 15 minutos)
* refresh tokens podem ser implementados para melhor UX
* transportado via header Authorization: Bearer <token>
* gerenciado pelo Bounded Context Identity

---

# 🏪 Comércio (Store)

## Store

Representa a identidade comercial de um Seller.

Uma Store:

* expõe produtos publicamente
* pertence a um Seller
* pode possuir branding e configurações de frete

---

## Product

Representa um produto conceitual.

Exemplos:

* Cesto Artesanal
* Caneca de Cerâmica
* Escultura de Madeira

Um Product:

* agrupa variantes vendáveis
* não necessariamente define o preço final
* pertence a uma Store

---

## Variant

Representa a versão vendável de um Product.

Exemplos:

* Cesto de Bambu
* Cesto de Metal
* Caneca Grande de Cerâmica

Uma Variant:

* possui preço
* possui estoque
* possui SKU
* pode possuir dimensões e peso
* é o item realmente comprável

Observações:

* o preço pertence à Variant
* o estoque pertence à Variant

---

# 🛒 Pedidos (Orders)

## Cart

Coleção temporária de itens selecionados pelo Buyer antes do checkout.

Características:

* mutável
* não persistente ou de curta duração
* não representa uma intenção finalizada de compra

---

## Order

Representa a intenção de compra do Buyer.

Uma Order:

* contém OrderItems
* possui estados
* pode transitar durante o ciclo de compra

Possíveis estados:

* pending
* paid
* shipped
* cancelled

Regras de negócio:

* uma Order não pode ser cancelada após envio
* os totais devem ser recalculados quando os itens mudam
* cupons podem afetar total e frete

---

## OrderItem

Representa o snapshot de um item comprado dentro de uma Order.

Um OrderItem armazena:

* referência da Variant
* quantidade
* snapshot do preço unitário
* snapshot opcional do nome do produto
* snapshot opcional do SKU

Importante:

OrderItem não deve depender de alterações futuras em Product ou Variant.

Motivo:

* preços podem mudar
* nomes podem mudar
* variantes podem ser removidas
* consistência financeira histórica deve ser preservada

---

# 📦 Estoque (Inventory)

## Inventory

Representa o estoque disponível de uma Variant.

Responsabilidades:

* controlar quantidade disponível
* reservar estoque
* confirmar consumo de estoque
* liberar estoque quando checkout falha

---

## Stock Reservation

Reserva temporária de estoque durante o checkout.

Objetivo:

Evitar venda acima da quantidade disponível enquanto o pagamento está sendo processado.

Fluxo:

1. reservar estoque
2. processar pagamento
3. confirmar ou liberar reserva

Observações:

* reservas podem expirar automaticamente
* reservas expiradas retornam quantidade ao estoque

---

# 🚚 Frete (Shipment)

## Shipment

Representa a operação de entrega relacionada a uma Order.

Responsabilidades:

* calcular frete
* definir estratégia de envio
* acompanhar estado da entrega

Possíveis responsáveis pelo frete:

* Buyer
* Seller

Exemplos:

* campanhas de frete grátis
* frete subsidiado pelo seller
* frete pago pelo buyer

---

# 💳 Pagamento (Payment)

## Payment

Representa a transação financeira associada a uma Order.

Possíveis estados:

* pending
* authorized
* paid
* failed
* refunded

Regras de negócio:

* pagamento aprovado confirma reserva de estoque
* pagamento falho libera reserva de estoque

---

# 🎟️ Promoções (Promotions)

## Coupon

Representa uma regra promocional que pode afetar uma Order.

Possíveis tipos:
* desconto percentual
* desconto fixo
* frete grátis

Possíveis restrições:
* primeira compra
* valor mínimo
* categoria específica
* variante específica
* período de validade

Regras de negócio:
* cupons devem ser validados antes da aplicação
* cupons inválidos não podem afetar a Order
* alteração de itens pode invalidar o Coupon
* Faz parte do bounded context Promotions (conforme ADR-008)

---

# Princípios de Domínio

## Princípio de Snapshot

Entidades financeiras e de pedido devem preservar dados históricos.

Exemplos:

* OrderItem armazena snapshot do preço
* Order não deve depender do preço atual da Variant

---

## Consistência Acima de Conveniência

Operações de estoque e pagamento priorizam consistência.

Exemplos:

* reserva de estoque antes da confirmação de pagamento
* uso de lock pessimista quando necessário

---

## Terminologia Explícita

Evitar termos ambíguos como:

* User
* Customer
* Item

Preferir:

* Seller
* Buyer
* Variant
* OrderItem

---

# 📚 Conceitos Futuros

Potential future concepts for platform evolution:

* Marketplace commissions
* Multi-store checkout
* Split payments
* Seller subscription plans
* External inventory integrations
* Fulfillment centers
* Recommendation engine
* Event-driven architecture
