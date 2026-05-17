require "rails_helper"

RSpec.describe Identity::Entities::Role do
  describe "#initialize" do
    context "quando todos os parâmetros são válidos" do
      it "cria um role buyer" do
        role = described_class.new(
          id: SecureRandom.uuid,
          name: described_class::BUYER,
          description: "Can purchase items"
        )

        expect(role.id).to be_a(String)
        expect(role.name).to eq(described_class::BUYER)
        expect(role.description).to eq("Can purchase items")
      end

      it "cria um role seller" do
        role = described_class.new(
          id: SecureRandom.uuid,
          name: described_class::SELLER
        )

        expect(role.name).to eq(described_class::SELLER)
      end

      it "cria um role platform_admin" do
        role = described_class.new(
          id: SecureRandom.uuid,
          name: described_class::PLATFORM_ADMIN
        )

        expect(role.name).to eq(described_class::PLATFORM_ADMIN)
      end

      it "predefine created_at e updated_at com timestamp atual" do
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

      it "aceita created_at e updated_at customizados" do
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

    context "quando name é inválido" do
      it "lança erro se name for nil" do
        expect {
          described_class.new(id: SecureRandom.uuid, name: nil)
        }.to raise_error(ArgumentError, "name cannot be nil or empty")
      end

      it "lança erro se name for vazio" do
        expect {
          described_class.new(id: SecureRandom.uuid, name: "")
        }.to raise_error(ArgumentError, "name cannot be nil or empty")
      end

      it "lança erro se name não estiver em VALID_NAMES" do
        expect {
          described_class.new(id: SecureRandom.uuid, name: "invalid_role")
        }.to raise_error(ArgumentError, /must be one of/)
      end

      it "inclui todas as opções válidas na mensagem de erro" do
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
    it "retorna true se role é buyer" do
      role = described_class.new(
        id: SecureRandom.uuid,
        name: described_class::BUYER
      )

      expect(role.buyer?).to be true
    end

    it "retorna false se role não é buyer" do
      role = described_class.new(
        id: SecureRandom.uuid,
        name: described_class::SELLER
      )

      expect(role.buyer?).to be false
    end
  end

  describe "#seller?" do
    it "retorna true se role é seller" do
      role = described_class.new(
        id: SecureRandom.uuid,
        name: described_class::SELLER
      )

      expect(role.seller?).to be true
    end

    it "retorna false se role não é seller" do
      role = described_class.new(
        id: SecureRandom.uuid,
        name: described_class::BUYER
      )

      expect(role.seller?).to be false
    end
  end

  describe "#admin?" do
    it "retorna true se role é platform_admin" do
      role = described_class.new(
        id: SecureRandom.uuid,
        name: described_class::PLATFORM_ADMIN
      )

      expect(role.admin?).to be true
    end

    it "retorna false se role não é platform_admin" do
      role = described_class.new(
        id: SecureRandom.uuid,
        name: described_class::SELLER
      )

      expect(role.admin?).to be false
    end
  end

  describe "igualdade e hash" do
    it "dois roles com mesmos atributos são iguais" do
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

    it "dois roles com atributos diferentes não são iguais" do
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

  describe "constantes de role" do
    it "define BUYER como 'buyer'" do
      expect(described_class::BUYER).to eq("buyer")
    end

    it "define SELLER como 'seller'" do
      expect(described_class::SELLER).to eq("seller")
    end

    it "define PLATFORM_ADMIN como 'platform_admin'" do
      expect(described_class::PLATFORM_ADMIN).to eq("platform_admin")
    end

    it "VALID_NAMES contém todos os roles válidos" do
      expect(described_class::VALID_NAMES).to contain_exactly(
        described_class::BUYER,
        described_class::SELLER,
        described_class::PLATFORM_ADMIN
      )
    end
  end
end
