# Domain - Okomo Marketplace

## Order
Represents the customer's purchase intention.

### Responsibilities:
- Manage items
- Apply discounts
- Calculate total
- Control state

### States:
- pending
- paid
- shipped
- cancelled

### Rules:
- Must have at least one item
- Total must be consistent with items and discounts
- Can only be cancelled before shipping
- Re-evaluates totals when items or coupons change

---

## OrderItem

### Responsibilities:
- Store product snapshot at purchase time
- Maintain quantity and price

### Rules:
- Price is immutable after order creation
- Belongs to Order aggregate

---

## Product

### Responsibilities:
- Represent product information

---

## Variant

### Responsibilities:
- Define purchasable variation
- Holds current price

---

## Coupon

### Responsibilities:
- Validate applicability
- Calculate discount

### Rules:
- Can be invalid due to date, quantity, or product rules
- Discount is stored as snapshot in Order
