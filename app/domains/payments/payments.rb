# frozen_string_literal: true

# Payments Domain
#
# Responsible for payment processing, payment methods, and transaction records.
# Handles payment authorization, capture, and refunds.
#
# Structure:
#   services/      - Business operations (e.g., process payment, refund)
#   entities/      - POROs representing domain concepts (not ActiveRecord)
#   value_objects/ - Immutable value types (e.g., Money, TransactionId)
#   repositories/  - Data access abstractions
#
module Payments
end
