# frozen_string_literal: true

# Inventory Domain
#
# Responsible for stock management, reservations, and inventory tracking.
# Handles stock levels, warehouse management, and availability checks.
#
# Structure:
#   services/      - Business operations (e.g., reserve stock, adjust inventory)
#   entities/      - POROs representing domain concepts (not ActiveRecord)
#   value_objects/ - Immutable value types (e.g., StockLevel, WarehouseId)
#   repositories/  - Data access abstractions
#
module Inventory
end
