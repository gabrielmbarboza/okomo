require "rails_helper"

RSpec.describe Identity::Entities::Role do
  describe "#initialize" do
    context "when all parameters are valid" do
      it "creates a buyer role" do
        role = described_class.new(
          id: SecureRandom.uuid,
          name: described_class::BUYER,
          description: "Can purchase items"
        )

        expect(role.id).to be_a(String)
        expect(role.name).to eq(described_class::BUYER)
        expect(role.description).to eq("Can purchase items")
      end

      it "creates a seller role" do
        role = described_class.new(
          id: SecureRandom.uuid,
          name: described_class::SELLER
        )

        expect(role.name).to eq(described_class::SELLER)
      end

      it "creates a platform_admin role" do
        role = described_class.new(
          id: SecureRandom.uuid,
          name: described_class::PLATFORM_ADMIN
        )

        expect(role.name).to eq(described_class::PLATFORM_ADMIN)
      end

      it "predefines created_at and updated_at with current timestamp" do
        now = Time.current
        role = described_class.new(
          id: SecureRandom.uuid,
          name: described_class::BUYER
        )

        expect(role.created_at).to be_a(ActiveSupport::TimeWithZone)
        expect(role.updated_at).to be_a(ActiveSupport::TimeWithZone)
        expect(role.created_at).to be >= now
        expect(role.updated_at).to be >= now
      end

      it "accepts custom created_at and updated_at" do
        time = 1.hour.ago
        role = described_class.new(
          id: SecureRandom.uuid,
          name: described_class::BUYER,
          created_at: time,
          updated_at: time
        )

        expect(role.created_at).to eq(time)
        expect(role.updated_at).to eq(time)
      end
    end

    context "when name is invalid" do
      it "raises an error if name is nil" do
        expect {
          described_class.new(id: SecureRandom.uuid, name: nil)
        }.to raise_error(ArgumentError, "name cannot be nil or empty")
      end

      it "raises an error if name is empty" do
        expect {
          described_class.new(id: SecureRandom.uuid, name: "")
        }.to raise_error(ArgumentError, "name cannot be nil or empty")
      end

      it "raises an error if name is not in VALID_NAMES" do
        expect {
          described_class.new(id: SecureRandom.uuid, name: "invalid_role")
        }.to raise_error(ArgumentError, /must be one of/)
      end

      it "includes all valid options in the error message" do
        error = nil
        begin
          described_class.new(id: SecureRandom.uuid, name: "invalid")
        rescue ArgumentError => e
          error = e
        end

        expect(error.message).to include(described_class::BUYER)
        expect(error.message).to include(described_class::SELLER)
        expect(error.message).to include(described_class::PLATFORM_ADMIN)
      end
    end
  end

  describe "#buyer?" do
    it "returns true if role is buyer" do
      role = described_class.new(
        id: SecureRandom.uuid,
        name: described_class::BUYER
      )

      expect(role.buyer?).to be true
    end

    it "returns false if role is not buyer" do
      role = described_class.new(
        id: SecureRandom.uuid,
        name: described_class::SELLER
      )

      expect(role.buyer?).to be false
    end
  end

  describe "#seller?" do
    it "returns true if role is seller" do
      role = described_class.new(
        id: SecureRandom.uuid,
        name: described_class::SELLER
      )

      expect(role.seller?).to be true
    end

    it "returns false if role is not seller" do
      role = described_class.new(
        id: SecureRandom.uuid,
        name: described_class::BUYER
      )

      expect(role.seller?).to be false
    end
  end

  describe "#admin?" do
    it "returns true if role is platform_admin" do
      role = described_class.new(
        id: SecureRandom.uuid,
        name: described_class::PLATFORM_ADMIN
      )

      expect(role.admin?).to be true
    end

    it "returns false if role is not platform_admin" do
      role = described_class.new(
        id: SecureRandom.uuid,
        name: described_class::SELLER
      )

      expect(role.admin?).to be false
    end
  end

  describe "equality and hash" do
    it "two roles with the same attributes are equal" do
      id = SecureRandom.uuid
      role1 = described_class.new(
        id: id,
        name: described_class::BUYER,
        created_at: Time.zone.parse("2026-05-17 10:00:00")
      )
      role2 = described_class.new(
        id: id,
        name: described_class::BUYER,
        created_at: Time.zone.parse("2026-05-17 10:00:00")
      )

      expect(role1).to eq(role2)
      expect(role1.eql?(role2)).to be true
      expect(role1.hash).to eq(role2.hash)
    end

    it "two roles with different attributes are not equal" do
      role1 = described_class.new(
        id: SecureRandom.uuid,
        name: described_class::BUYER
      )
      role2 = described_class.new(
        id: SecureRandom.uuid,
        name: described_class::SELLER
      )

      expect(role1).not_to eq(role2)
    end
  end

  describe "role constants" do
    it "defines BUYER as 'buyer'" do
      expect(described_class::BUYER).to eq("buyer")
    end

    it "defines SELLER as 'seller'" do
      expect(described_class::SELLER).to eq("seller")
    end

    it "defines PLATFORM_ADMIN as 'platform_admin'" do
      expect(described_class::PLATFORM_ADMIN).to eq("platform_admin")
    end

    it "VALID_NAMES contains all valid roles" do
      expect(described_class::VALID_NAMES).to contain_exactly(
        described_class::BUYER,
        described_class::SELLER,
        described_class::PLATFORM_ADMIN
      )
    end
  end
end
