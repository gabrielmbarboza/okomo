module Orders
  module Entities
    class Order
      STATUSES = %i[pending paid shipped cancelled].freeze

      attr_reader :customer_id, :items, :status

      def initialize(customer_id:)
        @customer_id = customer_id
        @items = []
        @status = :pending
      end

      def add_item(item)
        @items << item
      end

      def total_price
        @items.sum(&:total_price)
      end

      def cancel!
        raise 'Cannot cancel shipped order' if @status == :shipped
        @status = :cancelled
      end
    end
  end
end