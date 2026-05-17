require "rails_helper"

RSpec.describe Identity::Entities::UserRole do
  describe "#initialize" do
    context "quando todos os parâmetros são válidos" do
      it "cria um user_role ativo" do
        user_id = SecureRandom.uuid
        role_id = SecureRandom.uuid
        granted_at = Time.zone.parse("2026-05-17 10:00:00")

        user_role = described_class.new(
          id: SecureRandom.uuid,
          user_id: user_id,
          role_id: role_id,
          granted_at: granted_at,
          granted_by_user_id: SecureRandom.uuid,
          reason: "automatic on email confirmation"
        )

        expect(user_role.id).to be_a(String)
        expect(user_role.user_id).to eq(user_id)
        expect(user_role.role_id).to eq(role_id)
        expect(user_role.granted_at).to eq(granted_at)
        expect(user_role.revoked_at).to be_nil
        expect(user_role.reason).to eq("automatic on email confirmation")
      end

      it "cria um user_role revogado" do
        user_id = SecureRandom.uuid
        role_id = SecureRandom.uuid
        granted_at = Time.zone.parse("2026-05-17 10:00:00")
        revoked_at = Time.zone.parse("2026-05-20 14:00:00")

        user_role = described_class.new(
          id: SecureRandom.uuid,
          user_id: user_id,
          role_id: role_id,
          granted_at: granted_at,
          revoked_at: revoked_at,
          granted_by_user_id: SecureRandom.uuid,
          revoked_by_user_id: SecureRandom.uuid,
          reason: "violation of seller policy"
        )

        expect(user_role.granted_at).to eq(granted_at)
        expect(user_role.revoked_at).to eq(revoked_at)
        expect(user_role.revoked_by_user_id).to be_a(String)
      end

      it "predefine granted_at, created_at e updated_at com timestamp atual" do
        now = Time.current
        user_role = described_class.new(
          id: SecureRandom.uuid,
          user_id: SecureRandom.uuid,
          role_id: SecureRandom.uuid
        )

        expect(user_role.granted_at).to be >= now
        expect(user_role.created_at).to be >= now
        expect(user_role.updated_at).to be >= now
      end

      it "aceita parâmetros opcionais como nil" do
        user_role = described_class.new(
          id: SecureRandom.uuid,
          user_id: SecureRandom.uuid,
          role_id: SecureRandom.uuid,
          granted_by_user_id: nil,
          revoked_by_user_id: nil,
          reason: nil
        )

        expect(user_role.granted_by_user_id).to be_nil
        expect(user_role.revoked_by_user_id).to be_nil
        expect(user_role.reason).to be_nil
      end
    end

    context "quando parâmetros obrigatórios são inválidos" do
      it "lança erro se user_id for nil" do
        expect {
          described_class.new(
            id: SecureRandom.uuid,
            user_id: nil,
            role_id: SecureRandom.uuid
          )
        }.to raise_error(ArgumentError, "user_id cannot be nil")
      end

      it "lança erro se role_id for nil" do
        expect {
          described_class.new(
            id: SecureRandom.uuid,
            user_id: SecureRandom.uuid,
            role_id: nil
          )
        }.to raise_error(ArgumentError, "role_id cannot be nil")
      end

      it "lança erro se revoked_at for anterior a granted_at" do
        granted_at = Time.zone.parse("2026-05-17 10:00:00")
        revoked_at = Time.zone.parse("2026-05-17 09:00:00")

        expect {
          described_class.new(
            id: SecureRandom.uuid,
            user_id: SecureRandom.uuid,
            role_id: Identity::Entities::Role::SELLER,
            granted_at: granted_at,
            revoked_at: revoked_at
          )
        }.to raise_error(ArgumentError, "revoked_at cannot be before granted_at")
      end
    end
  end

  describe "#active?" do
    it "retorna true se revoked_at é nil" do
      user_role = described_class.new(
        id: SecureRandom.uuid,
        user_id: SecureRandom.uuid,
        role_id: SecureRandom.uuid,
        revoked_at: nil
      )

      expect(user_role.active?).to be true
    end

    it "retorna false se revoked_at está preenchido" do
      user_role = described_class.new(
        id: SecureRandom.uuid,
        user_id: SecureRandom.uuid,
        role_id: SecureRandom.uuid,
        revoked_at: Time.current
      )

      expect(user_role.active?).to be false
    end
  end

  describe "#revoked?" do
    it "retorna false se revoked_at é nil" do
      user_role = described_class.new(
        id: SecureRandom.uuid,
        user_id: SecureRandom.uuid,
        role_id: SecureRandom.uuid,
        revoked_at: nil
      )

      expect(user_role.revoked?).to be false
    end

    it "retorna true se revoked_at está preenchido" do
      user_role = described_class.new(
        id: SecureRandom.uuid,
        user_id: SecureRandom.uuid,
        role_id: SecureRandom.uuid,
        revoked_at: Time.current
      )

      expect(user_role.revoked?).to be true
    end
  end

  describe "#buyer?" do
    it "retorna true para role buyer" do
      user_role = described_class.new(
        id: SecureRandom.uuid,
        user_id: SecureRandom.uuid,
        role_id: Identity::Entities::Role::BUYER
      )

      expect(user_role.buyer?).to be true
    end

    it "retorna false para outros roles" do
      user_role = described_class.new(
        id: SecureRandom.uuid,
        user_id: SecureRandom.uuid,
        role_id: Identity::Entities::Role::SELLER
      )

      expect(user_role.buyer?).to be false
    end
  end

  describe "#revoke!" do
    it "revoga um role ativo e preserva dados de auditoria" do
      revoked_at = Time.zone.parse("2026-05-18 10:00:00")
      admin_id = SecureRandom.uuid
      user_role = described_class.new(
        id: SecureRandom.uuid,
        user_id: SecureRandom.uuid,
        role_id: Identity::Entities::Role::SELLER,
        granted_at: Time.zone.parse("2026-05-17 10:00:00")
      )

      result = user_role.revoke!(
        revoked_by_user_id: admin_id,
        reason: "policy violation",
        revoked_at: revoked_at
      )

      expect(result).to eq(user_role)
      expect(user_role.revoked?).to be true
      expect(user_role.revoked_at).to eq(revoked_at)
      expect(user_role.revoked_by_user_id).to eq(admin_id)
      expect(user_role.reason).to eq("policy violation")
      expect(user_role.updated_at).to eq(revoked_at)
    end

    it "não permite revogar buyer" do
      user_role = described_class.new(
        id: SecureRandom.uuid,
        user_id: SecureRandom.uuid,
        role_id: Identity::Entities::Role::BUYER
      )

      expect {
        user_role.revoke!(reason: "not allowed")
      }.to raise_error(ArgumentError, "buyer role cannot be revoked")
    end

    it "não permite revogar duas vezes" do
      user_role = described_class.new(
        id: SecureRandom.uuid,
        user_id: SecureRandom.uuid,
        role_id: Identity::Entities::Role::SELLER,
        revoked_at: Time.current
      )

      expect {
        user_role.revoke!(reason: "again")
      }.to raise_error(ArgumentError, "role already revoked")
    end
  end

  describe "#granted_ago" do
    it "calcula tempo decorrido desde concessão" do
      granted_at = 2.hours.ago
      user_role = described_class.new(
        id: SecureRandom.uuid,
        user_id: SecureRandom.uuid,
        role_id: SecureRandom.uuid,
        granted_at: granted_at
      )

      duration = user_role.granted_ago
      expect(duration).to be_a(Float)
      expect(duration).to be_within(5).of(2.hours)
    end

    it "retorna aproximadamente 0 para concessão recente" do
      granted_at = Time.current
      user_role = described_class.new(
        id: SecureRandom.uuid,
        user_id: SecureRandom.uuid,
        role_id: SecureRandom.uuid,
        granted_at: granted_at
      )

      duration = user_role.granted_ago
      expect(duration).to be_within(1).of(0)
    end
  end

  describe "#revoked_ago" do
    it "retorna nil se role não foi revogado" do
      user_role = described_class.new(
        id: SecureRandom.uuid,
        user_id: SecureRandom.uuid,
        role_id: SecureRandom.uuid,
        revoked_at: nil
      )

      expect(user_role.revoked_ago).to be_nil
    end

    it "calcula tempo decorrido desde revogação" do
      revoked_at = 1.hour.ago
      user_role = described_class.new(
        id: SecureRandom.uuid,
        user_id: SecureRandom.uuid,
        role_id: SecureRandom.uuid,
        revoked_at: revoked_at
      )

      duration = user_role.revoked_ago
      expect(duration).to be_a(Float)
      expect(duration).to be_within(5).of(1.hour)
    end
  end

  describe "#duration" do
    it "retorna duração desde concessão até revogação" do
      granted_at = Time.zone.parse("2026-05-17 10:00:00")
      revoked_at = Time.zone.parse("2026-05-17 14:00:00")
      expected_duration = 4.hours

      user_role = described_class.new(
        id: SecureRandom.uuid,
        user_id: SecureRandom.uuid,
        role_id: SecureRandom.uuid,
        granted_at: granted_at,
        revoked_at: revoked_at
      )

      expect(user_role.duration).to eq(expected_duration)
    end

    it "retorna duração desde concessão até agora se não foi revogado" do
      granted_at = 2.hours.ago
      user_role = described_class.new(
        id: SecureRandom.uuid,
        user_id: SecureRandom.uuid,
        role_id: SecureRandom.uuid,
        granted_at: granted_at,
        revoked_at: nil
      )

      duration = user_role.duration
      expect(duration).to be_a(Float)
      expect(duration).to be_within(5).of(2.hours)
    end

    it "retorna duração pequena se concessão é recente" do
      granted_at = 5.seconds.ago
      user_role = described_class.new(
        id: SecureRandom.uuid,
        user_id: SecureRandom.uuid,
        role_id: SecureRandom.uuid,
        granted_at: granted_at,
        revoked_at: nil
      )

      duration = user_role.duration
      expect(duration).to be < 1.minute
    end
  end

  describe "auditoria" do
    it "rastreia quem concedeu o role" do
      admin_id = SecureRandom.uuid
      user_role = described_class.new(
        id: SecureRandom.uuid,
        user_id: SecureRandom.uuid,
        role_id: SecureRandom.uuid,
        granted_by_user_id: admin_id
      )

      expect(user_role.granted_by_user_id).to eq(admin_id)
    end

    it "rastreia quem revogou o role" do
      admin_id = SecureRandom.uuid
      user_role = described_class.new(
        id: SecureRandom.uuid,
        user_id: SecureRandom.uuid,
        role_id: SecureRandom.uuid,
        revoked_by_user_id: admin_id
      )

      expect(user_role.revoked_by_user_id).to eq(admin_id)
    end

    it "registra razão da concessão ou revogação" do
      reason = "approved seller application #12345"
      user_role = described_class.new(
        id: SecureRandom.uuid,
        user_id: SecureRandom.uuid,
        role_id: SecureRandom.uuid,
        reason: reason
      )

      expect(user_role.reason).to eq(reason)
    end

    it "mantém histórico completo e imutável" do
      granted_at = Time.zone.parse("2026-05-17 10:00:00")
      revoked_at = Time.zone.parse("2026-05-20 14:00:00")
      granted_by = SecureRandom.uuid
      revoked_by = SecureRandom.uuid

      user_role = described_class.new(
        id: SecureRandom.uuid,
        user_id: SecureRandom.uuid,
        role_id: SecureRandom.uuid,
        granted_at: granted_at,
        granted_by_user_id: granted_by,
        revoked_at: revoked_at,
        revoked_by_user_id: revoked_by
      )

      expect(user_role.granted_at).to eq(granted_at)
      expect(user_role.granted_by_user_id).to eq(granted_by)
      expect(user_role.revoked_at).to eq(revoked_at)
      expect(user_role.revoked_by_user_id).to eq(revoked_by)
    end
  end

  describe "igualdade e hash" do
    it "dois user_roles com mesmos atributos são iguais" do
      id = SecureRandom.uuid
      user_id = SecureRandom.uuid
      role_id = SecureRandom.uuid
      granted_at = Time.zone.parse("2026-05-17 10:00:00")

      user_role1 = described_class.new(
        id: id,
        user_id: user_id,
        role_id: role_id,
        granted_at: granted_at
      )
      user_role2 = described_class.new(
        id: id,
        user_id: user_id,
        role_id: role_id,
        granted_at: granted_at
      )

      expect(user_role1).to eq(user_role2)
      expect(user_role1.eql?(user_role2)).to be true
      expect(user_role1.hash).to eq(user_role2.hash)
    end

    it "dois user_roles com atributos diferentes não são iguais" do
      user_role1 = described_class.new(
        id: SecureRandom.uuid,
        user_id: SecureRandom.uuid,
        role_id: SecureRandom.uuid
      )
      user_role2 = described_class.new(
        id: SecureRandom.uuid,
        user_id: SecureRandom.uuid,
        role_id: SecureRandom.uuid
      )

      expect(user_role1).not_to eq(user_role2)
    end
  end
end
