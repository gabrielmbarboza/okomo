require "rails_helper"

RSpec.describe Catalog::Entities::Product do
  describe "#initialize" do
    it "builds a valid product with defaults" do
      product = described_class.new(seller_profile_id: SecureRandom.uuid, name: "Cesto Artesanal")

      expect(product.id).to be_present
      expect(product.status).to eq("draft")
      expect(product.created_at).to be_present
      expect(product.updated_at).to eq(product.created_at)
    end

    it "accepts an explicit description" do
      product = described_class.new(
        seller_profile_id: SecureRandom.uuid,
        name: "Cesto Artesanal",
        description: "Feito à mão"
      )

      expect(product.description).to eq("Feito à mão")
    end

    it "raises when id is nil" do
      expect do
        described_class.new(id: nil, seller_profile_id: SecureRandom.uuid, name: "Cesto")
      end.to raise_error(ArgumentError, "id cannot be nil")
    end

    it "raises when seller_profile_id is blank" do
      expect do
        described_class.new(seller_profile_id: nil, name: "Cesto")
      end.to raise_error(ArgumentError, "seller_profile_id cannot be nil or empty")
    end

    it "raises when name is blank" do
      expect do
        described_class.new(seller_profile_id: SecureRandom.uuid, name: "")
      end.to raise_error(ArgumentError, "name cannot be nil or empty")
    end

    it "raises when status is invalid" do
      expect do
        described_class.new(seller_profile_id: SecureRandom.uuid, name: "Cesto", status: "unknown")
      end.to raise_error(ArgumentError, /status must be one of/)
    end
  end

  describe "#draft?/#published?/#archived?" do
    it "returns true for the matching status only" do
      product = described_class.new(seller_profile_id: SecureRandom.uuid, name: "Cesto")

      expect(product.draft?).to be(true)
      expect(product.published?).to be(false)
      expect(product.archived?).to be(false)
    end
  end

  describe "#publish!" do
    it "transitions a draft product with description to published" do
      product = described_class.new(
        seller_profile_id: SecureRandom.uuid,
        name: "Cesto",
        description: "Feito à mão"
      )
      published_at = Time.zone.parse("2026-07-14 10:00:00")

      product.publish!(published_at: published_at)

      expect(product.published?).to be(true)
      expect(product.updated_at).to eq(published_at)
    end

    it "raises when product is not draft" do
      product = described_class.new(
        seller_profile_id: SecureRandom.uuid,
        name: "Cesto",
        description: "Feito à mão",
        status: "published"
      )

      expect { product.publish! }.to raise_error(ArgumentError, "product must be draft to be published")
    end

    it "raises when product has no description" do
      product = described_class.new(seller_profile_id: SecureRandom.uuid, name: "Cesto")

      expect { product.publish! }.to raise_error(
        ArgumentError, "product must have a description to be published"
      )
    end
  end
end
