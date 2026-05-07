module Orders
  module Services
    class CreateOrder
      def self.call(customer_id:, items:)
        order = Orders::Entities::Order.new(customer_id: customer_id)

        items.each do |item_data|
          item = Orders::Entities::OrderItem.new(
            variant_id: item_data[:variant_id],
            quantity: item_data[:quantity],
            unit_price: item_data[:unit_price]
          )
          
          order.add_item(item)
        end

        order
      end
    end
  end
end