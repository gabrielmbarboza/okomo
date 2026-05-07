# 🧭 Okomo Roadmap (Senior-Level Execution Plan)

## 🎯 Goal
Build a **production-like marketplace system** with solid architecture, real domain modeling, and strong interview-ready explanations.

---

# 🚀 PHASE 1 — FOUNDATION

## 🎯 Objective
Move from structure → real domain implementation

### 🧹 Architectural Cleanup
- [ ] Remove `base_*` classes (entity, service, repository, value_object)
- [ ] Remove premature repositories
- [ ] Simplify `catalog.rb`, `orders.rb` (keep only namespace if needed)

### 🧱 Environment Setup
- [ ] Validate `database.yml` (`host: db`)
- [ ] Ensure UUID as default primary key
- [ ] Confirm `.env` with UID/GID
- [ ] Validate Docker setup (no root file issues)

---

# 🚀 PHASE 2 — CORE DOMAIN (ORDERS)

## 🎯 Objective
Implement the core of the system

### 🧠 Domain Modeling
- [ ] Create `Order` entity
- [ ] Create `OrderItem` entity
- [ ] Define states:
  - [ ] pending
  - [ ] paid
  - [ ] shipped
  - [ ] cancelled

### ⚙️ Business Rules
- [ ] add_item
- [ ] remove_item
- [ ] calculate_total
- [ ] apply_coupon (stub)

### 🔧 Use Cases
- [ ] Create `CreateOrder`
- [ ] Create `AddItemToOrder`
- [ ] Create `RemoveItemFromOrder`

### 💾 Persistence (Simple)
- [ ] Create `OrderRecord`
- [ ] Create `OrderItemRecord`

---

# 🚀 PHASE 3 — CATALOG

## 🎯 Objective
Provide products for orders

- [ ] Create `Product`
- [ ] Create `Variant`
- [ ] Define pricing in Variant

### ⚙️ Use Cases
- [ ] CreateProduct
- [ ] AddVariant

---

# 🚀 PHASE 4 — INVENTORY

## 🎯 Objective
Handle stock consistency

- [ ] Create `Inventory`
- [ ] Create `StockReservation`

### ⚙️ Operations
- [ ] reserve_stock
- [ ] release_stock
- [ ] confirm_stock

### ⏱️ Background Jobs
- [ ] Expiration job (Sidekiq)

---

# 🚀 PHASE 5 — SHIPPING

## 🎯 Objective
Handle delivery per seller

- [ ] Create `Shipment`
- [ ] Link Shipment to Order

### ⚙️ Rules
- [ ] calculate_shipping
- [ ] paid_by (seller/customer)

---

# 🚀 PHASE 6 — COUPONS

## 🎯 Objective
Controlled promotion engine

- [ ] Create `Coupon`

### 🎟️ Types
- [ ] percentage
- [ ] fixed amount
- [ ] free shipping

### ⚙️ Logic
- [ ] applicable_to?(order)
- [ ] calculate_discount(order)

---

# 🚀 PHASE 7 — CHECKOUT & PAYMENT

## 🎯 Objective
Full purchase flow

### 🛒 Checkout Flow
- [ ] reserve stock
- [ ] apply coupon
- [ ] calculate shipping

### 💳 Payment
- [ ] Create `Payment`
- [ ] Simulate:
  - [ ] success
  - [ ] failure

### 🔗 Integration
- [ ] success → confirm stock
- [ ] failure → release stock

---

# 🚀 PHASE 8 — CONCURRENCY

## 🎯 Objective
Ensure consistency

- [ ] Implement pessimistic locking (PostgreSQL)
- [ ] Ensure atomic operations for:
  - [ ] order
  - [ ] inventory

---

# 🚀 PHASE 9 — API LAYER

## 🎯 Objective
Expose the system

### 🌐 Endpoints
- [ ] create order
- [ ] add item
- [ ] checkout

### ⚠️ Rule
- Controllers must only orchestrate (no business logic)

---

# 🚀 PHASE 10 — QUALITY

## 🎯 Objective
Production-level quality

- [ ] Unit tests (domain)
- [ ] Service tests
- [ ] Structured logging
- [ ] Error handling

---

# 🚀 PHASE 11 — DIFFERENTIATION (INTERVIEW EDGE)

## 🎯 Objective
Stand out as senior

- [ ] Document architectural decisions
- [ ] Add trade-offs explanation
- [ ] Add system diagram
- [ ] Explain concurrency decisions
- [ ] Explain inventory strategy

---

# 🧠 EXECUTION STRATEGY

## ❗ Golden Rule
Do NOT build everything at once.

---

## 💎 Recommended Order

1. Orders (core)
2. Catalog
3. Inventory
4. Checkout
5. Shipping
6. Coupon
7. Payment

---

# 🔥 FINAL GOAL

- Real-world architecture
- Strong domain modeling
- Interview-ready explanations
- Production-like system design

---
