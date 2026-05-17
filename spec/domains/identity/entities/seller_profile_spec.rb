require "rails_helper"

RSpec.describe Identity::Entities::SellerProfile do
  describe "#initialize" do
    context "quando todos os parâmetros são válidos" do
      it "cria um novo seller profile" do
        seller_profile = described_class.new(
          id: SecureRandom.uuid,
          user_id: SecureRandom.uuid,
          display_name: "John's Shop"
        )

        expect(seller_profile.id).to be_a(String)
        expect(seller_profile.user_id).to be_a(String)
        expect(seller_profile.display_name).to eq("John's Shop")
        expect(seller_profile.status).to eq(described_class::PENDING_REVIEW)
        expect(seller_profile.requested_at).to be_a(ActiveSupport::TimeWithZone)
      end

      it "cria seller profile com todos os campos preenchidos" do
        user_id = SecureRandom.uuid
        reviewed_by_user_id = SecureRandom.uuid
        requested_at = Time.zone.parse("2026-05-17 10:00:00")
        approved_at = Time.zone.parse("2026-05-18 14:00:00")

        commercial_address = {
          "street" => "Rua das Flores",
          "number" => "123",
          "city" => "São Paulo",
          "state" => "SP",
          "zip_code" => "01310-100"
        }

        seller_profile = described_class.new(
          id: SecureRandom.uuid,
          user_id: user_id,
          display_name: "Jane's Crafts",
          description: "Artesanato em cerâmica",
          status: described_class::APPROVED,
          document_type: described_class::DOC_TYPE_CNPJ,
          document_number: "encrypted_cnpj_hash",
          legal_name: "Jane Silva CNPJ",
          contact_email: "jane@crafts.com",
          contact_phone: "11987654321",
          commercial_address: commercial_address,
          requested_at: requested_at,
          reviewed_at: approved_at,
          reviewed_by_user_id: reviewed_by_user_id,
          approved_at: approved_at
        )

        expect(seller_profile.user_id).to eq(user_id)
        expect(seller_profile.display_name).to eq("Jane's Crafts")
        expect(seller_profile.description).to eq("Artesanato em cerâmica")
        expect(seller_profile.status).to eq(described_class::APPROVED)
        expect(seller_profile.document_type).to eq(described_class::DOC_TYPE_CNPJ)
        expect(seller_profile.legal_name).to eq("Jane Silva CNPJ")
        expect(seller_profile.contact_email).to eq("jane@crafts.com")
        expect(seller_profile.commercial_address).to eq(commercial_address)
        expect(seller_profile.approved_at).to eq(approved_at)
      end

      it "predefine requested_at, created_at e updated_at com timestamp atual" do
        now = Time.current
        seller_profile = described_class.new(
          id: SecureRandom.uuid,
          user_id: SecureRandom.uuid,
          display_name: "Test Shop"
        )

        expect(seller_profile.requested_at).to be >= now
        expect(seller_profile.created_at).to be >= now
        expect(seller_profile.updated_at).to be >= now
      end
    end

    context "quando parâmetros obrigatórios são inválidos" do
      it "lança erro se user_id for nil" do
        expect {
          described_class.new(
            id: SecureRandom.uuid,
            user_id: nil,
            display_name: "Shop"
          )
        }.to raise_error(ArgumentError, "user_id cannot be nil")
      end

      it "lança erro se display_name for nil" do
        expect {
          described_class.new(
            id: SecureRandom.uuid,
            user_id: SecureRandom.uuid,
            display_name: nil
          )
        }.to raise_error(ArgumentError, "display_name cannot be nil or empty")
      end

      it "lança erro se display_name for vazio" do
        expect {
          described_class.new(
            id: SecureRandom.uuid,
            user_id: SecureRandom.uuid,
            display_name: ""
          )
        }.to raise_error(ArgumentError, "display_name cannot be nil or empty")
      end

      it "lança erro se status for inválido" do
        expect {
          described_class.new(
            id: SecureRandom.uuid,
            user_id: SecureRandom.uuid,
            display_name: "Shop",
            status: "invalid_status"
          )
        }.to raise_error(ArgumentError, /must be one of/)
      end

      it "lança erro se document_type for inválido" do
        expect {
          described_class.new(
            id: SecureRandom.uuid,
            user_id: SecureRandom.uuid,
            display_name: "Shop",
            document_type: "passport"
          )
        }.to raise_error(ArgumentError, /document_type must be one of/)
      end
    end
  end

  describe "#pending_review?" do
    it "retorna true se status é pending_review" do
      seller_profile = described_class.new(
        id: SecureRandom.uuid,
        user_id: SecureRandom.uuid,
        display_name: "Shop",
        status: described_class::PENDING_REVIEW
      )

      expect(seller_profile.pending_review?).to be true
    end

    it "retorna false se status não é pending_review" do
      seller_profile = described_class.new(
        id: SecureRandom.uuid,
        user_id: SecureRandom.uuid,
        display_name: "Shop",
        status: described_class::APPROVED
      )

      expect(seller_profile.pending_review?).to be false
    end
  end

  describe "#approved?" do
    it "retorna true se status é approved" do
      seller_profile = described_class.new(
        id: SecureRandom.uuid,
        user_id: SecureRandom.uuid,
        display_name: "Shop",
        status: described_class::APPROVED
      )

      expect(seller_profile.approved?).to be true
    end

    it "retorna false se status não é approved" do
      seller_profile = described_class.new(
        id: SecureRandom.uuid,
        user_id: SecureRandom.uuid,
        display_name: "Shop",
        status: described_class::REJECTED
      )

      expect(seller_profile.approved?).to be false
    end
  end

  describe "#rejected?" do
    it "retorna true se status é rejected" do
      seller_profile = described_class.new(
        id: SecureRandom.uuid,
        user_id: SecureRandom.uuid,
        display_name: "Shop",
        status: described_class::REJECTED
      )

      expect(seller_profile.rejected?).to be true
    end

    it "retorna false se status não é rejected" do
      seller_profile = described_class.new(
        id: SecureRandom.uuid,
        user_id: SecureRandom.uuid,
        display_name: "Shop",
        status: described_class::APPROVED
      )

      expect(seller_profile.rejected?).to be false
    end
  end

  describe "#suspended?" do
    it "retorna true se status é suspended" do
      seller_profile = described_class.new(
        id: SecureRandom.uuid,
        user_id: SecureRandom.uuid,
        display_name: "Shop",
        status: described_class::SUSPENDED
      )

      expect(seller_profile.suspended?).to be true
    end

    it "retorna false se status não é suspended" do
      seller_profile = described_class.new(
        id: SecureRandom.uuid,
        user_id: SecureRandom.uuid,
        display_name: "Shop",
        status: described_class::APPROVED
      )

      expect(seller_profile.suspended?).to be false
    end
  end

  describe "#can_sell?" do
    it "retorna true se status é approved" do
      seller_profile = described_class.new(
        id: SecureRandom.uuid,
        user_id: SecureRandom.uuid,
        display_name: "Shop",
        status: described_class::APPROVED
      )

      expect(seller_profile.can_sell?).to be true
    end

    it "retorna false se status é pending_review" do
      seller_profile = described_class.new(
        id: SecureRandom.uuid,
        user_id: SecureRandom.uuid,
        display_name: "Shop",
        status: described_class::PENDING_REVIEW
      )

      expect(seller_profile.can_sell?).to be false
    end

    it "retorna false se status é rejected" do
      seller_profile = described_class.new(
        id: SecureRandom.uuid,
        user_id: SecureRandom.uuid,
        display_name: "Shop",
        status: described_class::REJECTED
      )

      expect(seller_profile.can_sell?).to be false
    end

    it "retorna false se status é suspended" do
      seller_profile = described_class.new(
        id: SecureRandom.uuid,
        user_id: SecureRandom.uuid,
        display_name: "Shop",
        status: described_class::SUSPENDED
      )

      expect(seller_profile.can_sell?).to be false
    end
  end

  describe "#approve!" do
    it "aprova um seller profile em revisão" do
      reviewed_at = Time.zone.parse("2026-05-18 10:00:00")
      reviewer_id = SecureRandom.uuid
      seller_profile = described_class.new(
        id: SecureRandom.uuid,
        user_id: SecureRandom.uuid,
        display_name: "Shop"
      )

      result = seller_profile.approve!(
        reviewed_by_user_id: reviewer_id,
        reviewed_at: reviewed_at
      )

      expect(result).to eq(seller_profile)
      expect(seller_profile.status).to eq(described_class::APPROVED)
      expect(seller_profile.reviewed_at).to eq(reviewed_at)
      expect(seller_profile.reviewed_by_user_id).to eq(reviewer_id)
      expect(seller_profile.approved_at).to eq(reviewed_at)
      expect(seller_profile.can_sell?).to be true
    end

    it "não aprova quando não está em pending_review" do
      seller_profile = described_class.new(
        id: SecureRandom.uuid,
        user_id: SecureRandom.uuid,
        display_name: "Shop",
        status: described_class::SUSPENDED
      )

      expect {
        seller_profile.approve!(reviewed_by_user_id: SecureRandom.uuid)
      }.to raise_error(ArgumentError, "seller profile must be pending_review")
    end
  end

  describe "#reject!" do
    it "rejeita um seller profile em revisão com motivo" do
      reviewed_at = Time.zone.parse("2026-05-18 11:00:00")
      reviewer_id = SecureRandom.uuid
      seller_profile = described_class.new(
        id: SecureRandom.uuid,
        user_id: SecureRandom.uuid,
        display_name: "Shop"
      )

      seller_profile.reject!(
        reviewed_by_user_id: reviewer_id,
        reason: "document invalid",
        reviewed_at: reviewed_at
      )

      expect(seller_profile.status).to eq(described_class::REJECTED)
      expect(seller_profile.reviewed_at).to eq(reviewed_at)
      expect(seller_profile.reviewed_by_user_id).to eq(reviewer_id)
      expect(seller_profile.rejected_at).to eq(reviewed_at)
      expect(seller_profile.rejection_reason).to eq("document invalid")
    end

    it "exige motivo de rejeição" do
      seller_profile = described_class.new(
        id: SecureRandom.uuid,
        user_id: SecureRandom.uuid,
        display_name: "Shop"
      )

      expect {
        seller_profile.reject!(reviewed_by_user_id: SecureRandom.uuid, reason: "")
      }.to raise_error(ArgumentError, "rejection_reason cannot be nil or empty")
    end
  end

  describe "#suspend!" do
    it "suspende um seller profile aprovado" do
      suspended_at = Time.zone.parse("2026-05-19 10:00:00")
      seller_profile = described_class.new(
        id: SecureRandom.uuid,
        user_id: SecureRandom.uuid,
        display_name: "Shop",
        status: described_class::APPROVED
      )

      seller_profile.suspend!(reason: "policy violation", suspended_at: suspended_at)

      expect(seller_profile.status).to eq(described_class::SUSPENDED)
      expect(seller_profile.suspended_at).to eq(suspended_at)
      expect(seller_profile.suspension_reason).to eq("policy violation")
      expect(seller_profile.can_sell?).to be false
    end

    it "exige motivo de suspensão" do
      seller_profile = described_class.new(
        id: SecureRandom.uuid,
        user_id: SecureRandom.uuid,
        display_name: "Shop",
        status: described_class::APPROVED
      )

      expect {
        seller_profile.suspend!(reason: nil)
      }.to raise_error(ArgumentError, "suspension_reason cannot be nil or empty")
    end
  end

  describe "#reactivate!" do
    it "reativa um seller profile suspenso" do
      seller_profile = described_class.new(
        id: SecureRandom.uuid,
        user_id: SecureRandom.uuid,
        display_name: "Shop",
        status: described_class::SUSPENDED,
        suspended_at: Time.zone.parse("2026-05-19 10:00:00"),
        suspension_reason: "policy violation"
      )

      seller_profile.reactivate!(reactivated_at: Time.zone.parse("2026-05-20 10:00:00"))

      expect(seller_profile.status).to eq(described_class::APPROVED)
      expect(seller_profile.suspended_at).to be_nil
      expect(seller_profile.suspension_reason).to be_nil
      expect(seller_profile.can_sell?).to be true
    end

    it "não reativa quando não está suspenso" do
      seller_profile = described_class.new(
        id: SecureRandom.uuid,
        user_id: SecureRandom.uuid,
        display_name: "Shop"
      )

      expect {
        seller_profile.reactivate!
      }.to raise_error(ArgumentError, "seller profile must be suspended")
    end
  end

  describe "#requested_days_ago" do
    it "retorna número de dias desde a solicitação" do
      requested_at = 5.days.ago
      seller_profile = described_class.new(
        id: SecureRandom.uuid,
        user_id: SecureRandom.uuid,
        display_name: "Shop",
        requested_at: requested_at
      )

      days_ago = seller_profile.requested_days_ago
      expect(days_ago).to be_a(Integer)
      expect(days_ago).to eq(5)
    end

    it "retorna 0 se solicitação é recente" do
      requested_at = 2.minutes.ago
      seller_profile = described_class.new(
        id: SecureRandom.uuid,
        user_id: SecureRandom.uuid,
        display_name: "Shop",
        requested_at: requested_at
      )

      days_ago = seller_profile.requested_days_ago
      expect(days_ago).to eq(0)
    end
  end

  describe "#approved_days_ago" do
    it "retorna nil se não foi aprovado" do
      seller_profile = described_class.new(
        id: SecureRandom.uuid,
        user_id: SecureRandom.uuid,
        display_name: "Shop",
        status: described_class::PENDING_REVIEW,
        approved_at: nil
      )

      expect(seller_profile.approved_days_ago).to be_nil
    end

    it "retorna número de dias desde aprovação" do
      approved_at = 3.days.ago
      seller_profile = described_class.new(
        id: SecureRandom.uuid,
        user_id: SecureRandom.uuid,
        display_name: "Shop",
        approved_at: approved_at
      )

      days_ago = seller_profile.approved_days_ago
      expect(days_ago).to be_a(Integer)
      expect(days_ago).to eq(3)
    end
  end

  describe "#review_duration_days" do
    it "retorna nil se não foi revisado" do
      seller_profile = described_class.new(
        id: SecureRandom.uuid,
        user_id: SecureRandom.uuid,
        display_name: "Shop",
        reviewed_at: nil
      )

      expect(seller_profile.review_duration_days).to be_nil
    end

    it "retorna número de dias levados para revisar" do
      requested_at = Time.zone.parse("2026-05-17 10:00:00")
      reviewed_at = Time.zone.parse("2026-05-19 14:00:00")

      seller_profile = described_class.new(
        id: SecureRandom.uuid,
        user_id: SecureRandom.uuid,
        display_name: "Shop",
        requested_at: requested_at,
        reviewed_at: reviewed_at
      )

      duration = seller_profile.review_duration_days
      expect(duration).to eq(2)
    end

    it "retorna 0 se revisão foi no mesmo dia" do
      requested_at = Time.zone.parse("2026-05-17 10:00:00")
      reviewed_at = Time.zone.parse("2026-05-17 14:00:00")

      seller_profile = described_class.new(
        id: SecureRandom.uuid,
        user_id: SecureRandom.uuid,
        display_name: "Shop",
        requested_at: requested_at,
        reviewed_at: reviewed_at
      )

      duration = seller_profile.review_duration_days
      expect(duration).to eq(0)
    end
  end

  describe "constantes de status" do
    it "define todos os status válidos" do
      expect(described_class::PENDING_REVIEW).to eq("pending_review")
      expect(described_class::APPROVED).to eq("approved")
      expect(described_class::REJECTED).to eq("rejected")
      expect(described_class::SUSPENDED).to eq("suspended")
    end

    it "VALID_STATUSES contém todos os status" do
      expect(described_class::VALID_STATUSES).to contain_exactly(
        described_class::PENDING_REVIEW,
        described_class::APPROVED,
        described_class::REJECTED,
        described_class::SUSPENDED
      )
    end
  end

  describe "constantes de tipo de documento" do
    it "define tipos de documento válidos" do
      expect(described_class::DOC_TYPE_CPF).to eq("cpf")
      expect(described_class::DOC_TYPE_CNPJ).to eq("cnpj")
      expect(described_class::DOC_TYPE_MEI).to eq("mei")
    end

    it "VALID_DOCUMENT_TYPES contém todos os tipos" do
      expect(described_class::VALID_DOCUMENT_TYPES).to contain_exactly(
        described_class::DOC_TYPE_CPF,
        described_class::DOC_TYPE_CNPJ,
        described_class::DOC_TYPE_MEI
      )
    end
  end

  describe "igualdade e hash" do
    it "dois seller profiles com mesmos atributos são iguais" do
      id = SecureRandom.uuid
      user_id = SecureRandom.uuid

      profile1 = described_class.new(
        id: id,
        user_id: user_id,
        display_name: "Shop",
        requested_at: Time.zone.parse("2026-05-17 10:00:00")
      )

      profile2 = described_class.new(
        id: id,
        user_id: user_id,
        display_name: "Shop",
        requested_at: Time.zone.parse("2026-05-17 10:00:00")
      )

      expect(profile1).to eq(profile2)
      expect(profile1.hash).to eq(profile2.hash)
    end

    it "dois seller profiles com atributos diferentes não são iguais" do
      profile1 = described_class.new(
        id: SecureRandom.uuid,
        user_id: SecureRandom.uuid,
        display_name: "Shop 1"
      )

      profile2 = described_class.new(
        id: SecureRandom.uuid,
        user_id: SecureRandom.uuid,
        display_name: "Shop 2"
      )

      expect(profile1).not_to eq(profile2)
    end
  end
end
