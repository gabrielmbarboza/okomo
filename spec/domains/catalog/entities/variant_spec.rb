require "rails_helper"

RSpec.describe Catalog::Entities::Variant do
  let(:product_id) { SecureRandom.uuid }

  describe "#initialize" do
    it "builds a valid variant with defaults" do
      variant = described_class.new(product_id: product_id, name: "Cesto de Bambu", sku: "CESTO-BAMBU", price: 49.9)

      expect(variant.id).to be_present
      expect(variant.status).to eq("draft")
      expect(variant.created_at).to be_present
      expect(variant.updated_at).to eq(variant.created_at)
    end

    it "raises when id is nil" do
      expect do
        described_class.new(id: nil, product_id: product_id, name: "Cesto", sku: "SKU-1", price: 10)
      end.to raise_error(ArgumentError, "id cannot be nil")
    end

    it "raises when product_id is blank" do
      expect do
        described_class.new(product_id: nil, name: "Cesto", sku: "SKU-1", price: 10)
      end.to raise_error(ArgumentError, "product_id cannot be nil or empty")
    end

    it "raises when name is blank" do
      expect do
        described_class.new(product_id: product_id, name: "", sku: "SKU-1", price: 10)
      end.to raise_error(ArgumentError, "name cannot be nil or empty")
    end

    it "raises when sku is blank" do
      expect do
        described_class.new(product_id: product_id, name: "Cesto", sku: "", price: 10)
      end.to raise_error(ArgumentError, "sku cannot be nil or empty")
    end

    it "raises when status is invalid" do
      expect do
        described_class.new(product_id: product_id, name: "Cesto", sku: "SKU-1", price: 10, status: "unknown")
      end.to raise_error(ArgumentError, /status must be one of/)
    end

    context "price validation (BR-CAT-011)" do
      it "raises when price is nil" do
        expect do
          described_class.new(product_id: product_id, name: "Cesto", sku: "SKU-1", price: nil)
        end.to raise_error(ArgumentError, "price must be greater than zero")
      end

      it "raises when price is zero" do
        expect do
          described_class.new(product_id: product_id, name: "Cesto", sku: "SKU-1", price: 0)
        end.to raise_error(ArgumentError, "price must be greater than zero")
      end

      it "raises when price is negative" do
        expect do
          described_class.new(product_id: product_id, name: "Cesto", sku: "SKU-1", price: -1)
        end.to raise_error(ArgumentError, "price must be greater than zero")
      end
    end

    context "dimensions validation (BR-CAT-012)" do
      %i[weight_grams height_cm width_cm length_cm].each do |attribute_name|
        it "raises when #{attribute_name} is zero" do
          expect do
            described_class.new(
              product_id: product_id, name: "Cesto", sku: "SKU-1", price: 10, attribute_name => 0
            )
          end.to raise_error(ArgumentError, "#{attribute_name} must be positive")
        end

        it "raises when #{attribute_name} is negative" do
          expect do
            described_class.new(
              product_id: product_id, name: "Cesto", sku: "SKU-1", price: 10, attribute_name => -1
            )
          end.to raise_error(ArgumentError, "#{attribute_name} must be positive")
        end

        it "accepts a nil #{attribute_name}" do
          variant = described_class.new(
            product_id: product_id, name: "Cesto", sku: "SKU-1", price: 10, attribute_name => nil
          )

          expect(variant.public_send(attribute_name)).to be_nil
        end
      end
    end
  end

  describe "#sellable?" do
    it "is true for draft and published variants" do
      draft = described_class.new(product_id: product_id, name: "Cesto", sku: "SKU-1", price: 10)
      published = described_class.new(
        product_id: product_id, name: "Cesto", sku: "SKU-2", price: 10, status: "published"
      )

      expect(draft.sellable?).to be(true)
      expect(published.sellable?).to be(true)
    end

    it "is false for archived variants" do
      archived = described_class.new(
        product_id: product_id, name: "Cesto", sku: "SKU-3", price: 10, status: "archived"
      )

      expect(archived.sellable?).to be(false)
    end
  end
end
