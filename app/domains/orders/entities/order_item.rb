module Orders
  module Entities
    class OrderItem
      attr_reader :variant_id, :quantity, :unit_price
      
      def initialize(variant_id:, quantity:, unit_price:)
        raise ArgumentError, "variant_id cannot be nil" if variant_id.nil?
        raise ArgumentError, "quantity must be greater than 0" if quantity <= 0
        raise ArgumentError, "unit_price must be greater than 0" if unit_price <= 0
        
        @variant_id = variant_id
        @quantity = quantity
        @unit_price = unit_price
      end

      def total_price
        @quantity * @unit_price
      end
    end
  end
end