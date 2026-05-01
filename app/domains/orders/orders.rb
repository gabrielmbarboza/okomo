# frozen_string_literal: true

# Orders Domain
#
# Responsible for managing customer orders, order items, and order lifecycle.
# Handles order creation, state transitions, and total calculations.
#
# Structure:
#   services/      - Business operations (e.g., create order, cancel order)
#   entities/      - POROs representing domain concepts (not ActiveRecord)
#   value_objects/ - Immutable value types (e.g., OrderTotal, OrderStatus)
#   repositories/  - Data access abstractions
#
module Orders
end
