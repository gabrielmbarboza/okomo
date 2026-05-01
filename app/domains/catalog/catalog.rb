# frozen_string_literal: true

# Catalog Domain
#
# Responsible for product information, categories, and variants.
# This domain manages the product catalog for the marketplace.
#
# Structure:
#   services/    - Business operations (e.g., create product, update pricing)
#   entities/    - POROs representing domain concepts (not ActiveRecord)
#   value_objects/ - Immutable value types (e.g., Money, SKU)
#   repositories/  - Data access abstractions
#
module Catalog
  # Load domain components
  require_relative 'entities'
  require_relative 'services'
end
