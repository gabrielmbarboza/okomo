# Flow - Create Order

1. User selects products
2. System validates variants
3. Create Order (pending)
4. Create OrderItems with price snapshot
5. Calculate total
6. Apply coupon (if any)
7. Persist order

## Notes
- Order recalculates totals on any change
- Coupon is validated and applied at order level
- Freight calculation may change with item updates
