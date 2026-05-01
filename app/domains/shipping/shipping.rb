# frozen_string_literal: true

# Shipping Domain
#
# Responsible for shipment tracking, carrier integrations, and delivery management.
# Handles shipping calculations, label generation, and delivery status updates.
#
# Structure:
#   services/      - Business operations (e.g., calculate shipping, track package)
#   entities/      - POROs representing domain concepts (not ActiveRecord)
#   value_objects/ - Immutable value types (e.g., Address, TrackingCode)
#   repositories/  - Data access abstractions
#
module Shipping
end
