require "rails_helper"

RSpec.describe Orders::Entities::OrderItem do
  describe "#initialize" do
    let(:variant_id) { 1 }
    let(:quantity) { 1 }
    let(:unit_price) { 10 }

    
    context "when all parameters are valid" do
      it "creates an order item" do
        expect { described_class.new(variant_id: variant_id, quantity: quantity, unit_price: unit_price) }.not_to raise_error
      end
    end
    
    context "when variant_id is nil" do
      it "raises an error" do
        expect { described_class.new(variant_id: nil, quantity: quantity, unit_price: unit_price) }.to raise_error(ArgumentError, "variant_id cannot be nil")
      end
    end

    context "when quantity is less than or equal to 0" do
      it "raises an error" do
        expect { described_class.new(variant_id: variant_id, quantity: 0, unit_price: unit_price) }.to raise_error(ArgumentError, "quantity must be greater than 0")
      end
    end

    context "when unit_price is less than or equal to 0" do
      it "raises an error" do
        expect { described_class.new(variant_id: variant_id, quantity: quantity, unit_price: 0) }.to raise_error(ArgumentError, "unit_price must be greater than 0")
      end
    end
  end

  describe "#total_price" do
    let(:variant_id) { 1 }
    let(:quantity) { 2 }
    let(:unit_price) { 10 }

    it "calculates the total price" do
      order_item = described_class.new(variant_id: variant_id, quantity: quantity, unit_price: unit_price)
      expect(order_item.total_price).to eq(20)
    end
  end
end