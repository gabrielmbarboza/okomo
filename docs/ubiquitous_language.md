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

## Seller

Pessoa física ou jurídica responsável pela venda de produtos na plataforma.

Responsabilidades:

* criar produtos
* gerenciar variantes
* definir preços
* gerenciar estoque
* criar cupons e promoções
* configurar estratégias de frete

Observações:

* um Seller pode possuir uma ou múltiplas Stores
* espera-se que o Seller possua registro legal válido (MEI/CNPJ)

---

## Buyer

Pessoa responsável por realizar compras na plataforma.

Responsabilidades:

* navegar pelo catálogo
* adicionar itens ao carrinho
* criar pedidos
* realizar checkout
* concluir pagamento

---

# 🏪 Comércio

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

# 🛒 Pedidos

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

# 📦 Estoque

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

# 🚚 Frete

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

# 💳 Pagamento

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

# 🎟️ Promoções

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

---

# 🧠 Princípios de Domínio

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

---



---

# 📘 TEMPLATE DE CASO DE USO

# Nome do Caso de Uso

## Objetivo

Descrever claramente o propósito do fluxo.

---

## Atores

* Buyer
* Seller
* Sistema

---

## Pré-condições

* Estado necessário antes da execução.

---

## Fluxo Principal

1. Ação principal
2. Validação
3. Persistência
4. Resultado

---

## Fluxos Alternativos

### Exemplo: estoque insuficiente

* operação interrompida
* mensagem de erro retornada

---

## Pós-condições

* Estado esperado após execução.

---

## Regras de Negócio

* Invariantes
* Regras financeiras
* Regras de consistência

---

# 🔥 Observações Finais

Este documento deve evoluir junto com o domínio.

A linguagem ubíqua é considerada parte da arquitetura e deve ser continuamente refinada conforme novas regras de negócio surgirem.
