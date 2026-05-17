require "rails_helper"

RSpec.describe Identity::Entities::User do
  describe "#initialize" do
    context "quando todos os parâmetros são válidos" do
      it "cria um novo usuário" do
        user = described_class.new(
          id: SecureRandom.uuid,
          email: "john@example.com",
          password_digest: "$2a$12$hash"
        )

        expect(user.id).to be_a(String)
        expect(user.email).to eq("john@example.com")
        expect(user.password_digest).to eq("$2a$12$hash")
        expect(user.status).to eq(described_class::PENDING_CONFIRMATION)
        expect(user.email_confirmed_at).to be_nil
        expect(user.user_roles).to eq([])
        expect(user.seller_profile).to be_nil
      end

      it "cria usuário com status padrão pending_confirmation" do
        user = described_class.new(
          id: SecureRandom.uuid,
          email: "jane@example.com",
          password_digest: "$2a$12$hash"
        )

        expect(user.status).to eq(described_class::PENDING_CONFIRMATION)
      end

      it "cria usuário com todos os campos opcionais preenchidos" do
        email_confirmed_at = Time.zone.parse("2026-05-17 10:00:00")
        last_login_at = Time.zone.parse("2026-05-17 11:00:00")
        created_at = Time.zone.parse("2026-05-17 08:00:00")

        user_role = Identity::Entities::UserRole.new(
          id: SecureRandom.uuid,
          user_id: SecureRandom.uuid,
          role_id: "buyer"
        )

        user = described_class.new(
          id: SecureRandom.uuid,
          name: "John Doe",
          email: "john@example.com",
          password_digest: "$2a$12$hash",
          status: described_class::ACTIVE,
          email_confirmed_at: email_confirmed_at,
          last_login_at: last_login_at,
          user_roles: [user_role],
          created_at: created_at,
          updated_at: created_at
        )

        expect(user.name).to eq("John Doe")
        expect(user.status).to eq(described_class::ACTIVE)
        expect(user.email_confirmed_at).to eq(email_confirmed_at)
        expect(user.last_login_at).to eq(last_login_at)
        expect(user.user_roles).to include(user_role)
        expect(user.created_at).to eq(created_at)
      end
    end

    context "quando parâmetros obrigatórios são inválidos" do
      it "lança erro se email for nil" do
        expect {
          described_class.new(
            id: SecureRandom.uuid,
            email: nil,
            password_digest: "$2a$12$hash"
          )
        }.to raise_error(ArgumentError, "email cannot be nil or empty")
      end

      it "lança erro se email for vazio" do
        expect {
          described_class.new(
            id: SecureRandom.uuid,
            email: "",
            password_digest: "$2a$12$hash"
          )
        }.to raise_error(ArgumentError, "email cannot be nil or empty")
      end

      it "lança erro se password_digest for nil" do
        expect {
          described_class.new(
            id: SecureRandom.uuid,
            email: "john@example.com",
            password_digest: nil
          )
        }.to raise_error(ArgumentError, "password_digest cannot be nil or empty")
      end

      it "lança erro se status for inválido" do
        expect {
          described_class.new(
            id: SecureRandom.uuid,
            email: "john@example.com",
            password_digest: "$2a$12$hash",
            status: "invalid_status"
          )
        }.to raise_error(ArgumentError, /must be one of/)
      end
    end
  end

  describe "#email_confirmed?" do
    it "retorna false se email_confirmed_at é nil" do
      user = described_class.new(
        id: SecureRandom.uuid,
        email: "john@example.com",
        password_digest: "$2a$12$hash",
        email_confirmed_at: nil
      )

      expect(user.email_confirmed?).to be false
    end

    it "retorna true se email_confirmed_at está preenchido" do
      user = described_class.new(
        id: SecureRandom.uuid,
        email: "john@example.com",
        password_digest: "$2a$12$hash",
        email_confirmed_at: Time.current
      )

      expect(user.email_confirmed?).to be true
    end
  end

  describe "#active?" do
    it "retorna true se status é active" do
      user = described_class.new(
        id: SecureRandom.uuid,
        email: "john@example.com",
        password_digest: "$2a$12$hash",
        status: described_class::ACTIVE
      )

      expect(user.active?).to be true
    end

    it "retorna false se status não é active" do
      user = described_class.new(
        id: SecureRandom.uuid,
        email: "john@example.com",
        password_digest: "$2a$12$hash",
        status: described_class::PENDING_CONFIRMATION
      )

      expect(user.active?).to be false
    end
  end

  describe "#blocked?" do
    it "retorna true se status é blocked" do
      user = described_class.new(
        id: SecureRandom.uuid,
        email: "john@example.com",
        password_digest: "$2a$12$hash",
        status: described_class::BLOCKED
      )

      expect(user.blocked?).to be true
    end

    it "retorna false se status não é blocked" do
      user = described_class.new(
        id: SecureRandom.uuid,
        email: "john@example.com",
        password_digest: "$2a$12$hash",
        status: described_class::ACTIVE
      )

      expect(user.blocked?).to be false
    end
  end

  describe "#deactivated?" do
    it "retorna true se status é deactivated" do
      user = described_class.new(
        id: SecureRandom.uuid,
        email: "john@example.com",
        password_digest: "$2a$12$hash",
        status: described_class::DEACTIVATED
      )

      expect(user.deactivated?).to be true
    end

    it "retorna false se status não é deactivated" do
      user = described_class.new(
        id: SecureRandom.uuid,
        email: "john@example.com",
        password_digest: "$2a$12$hash",
        status: described_class::ACTIVE
      )

      expect(user.deactivated?).to be false
    end
  end

  describe "#can_login?" do
    it "retorna true se ativo e email confirmado" do
      user = described_class.new(
        id: SecureRandom.uuid,
        email: "john@example.com",
        password_digest: "$2a$12$hash",
        status: described_class::ACTIVE,
        email_confirmed_at: Time.current
      )

      expect(user.can_login?).to be true
    end

    it "retorna false se status não é active" do
      user = described_class.new(
        id: SecureRandom.uuid,
        email: "john@example.com",
        password_digest: "$2a$12$hash",
        status: described_class::BLOCKED,
        email_confirmed_at: Time.current
      )

      expect(user.can_login?).to be false
    end

    it "retorna false se email não foi confirmado" do
      user = described_class.new(
        id: SecureRandom.uuid,
        email: "john@example.com",
        password_digest: "$2a$12$hash",
        status: described_class::ACTIVE,
        email_confirmed_at: nil
      )

      expect(user.can_login?).to be false
    end
  end

  describe "#confirm_email!" do
    it "confirma email, ativa o user e concede buyer automaticamente" do
      confirmed_at = Time.zone.parse("2026-05-17 10:00:00")
      user = described_class.new(
        id: SecureRandom.uuid,
        email: "john@example.com",
        password_digest: "$2a$12$hash"
      )

      result = user.confirm_email!(confirmed_at: confirmed_at)

      expect(result).to eq(user)
      expect(user.status).to eq(described_class::ACTIVE)
      expect(user.email_confirmed_at).to eq(confirmed_at)
      expect(user.buyer?).to be true
      expect(user.user_roles.size).to eq(1)
      expect(user.user_roles.first.role_id).to eq(Identity::Entities::Role::BUYER)
      expect(user.user_roles.first.reason).to eq("automatic on email confirmation")
    end

    it "não duplica buyer se email já estava confirmado" do
      confirmed_at = Time.zone.parse("2026-05-17 10:00:00")
      user = described_class.new(
        id: SecureRandom.uuid,
        email: "john@example.com",
        password_digest: "$2a$12$hash"
      )

      user.confirm_email!(confirmed_at: confirmed_at)
      user.confirm_email!(confirmed_at: 1.hour.from_now)

      expect(user.user_roles.count { |role| role.role_id == Identity::Entities::Role::BUYER }).to eq(1)
      expect(user.email_confirmed_at).to eq(confirmed_at)
    end
  end

  describe "#grant_role" do
    it "concede um role válido e auditável" do
      granted_at = Time.zone.parse("2026-05-18 10:00:00")
      admin_id = SecureRandom.uuid
      user = described_class.new(
        id: SecureRandom.uuid,
        email: "john@example.com",
        password_digest: "$2a$12$hash"
      )

      user_role = user.grant_role(
        Identity::Entities::Role::SELLER,
        granted_by_user_id: admin_id,
        reason: "approved seller application",
        granted_at: granted_at
      )

      expect(user_role.role_id).to eq(Identity::Entities::Role::SELLER)
      expect(user_role.granted_by_user_id).to eq(admin_id)
      expect(user_role.reason).to eq("approved seller application")
      expect(user_role.granted_at).to eq(granted_at)
      expect(user.seller?).to be true
    end

    it "não duplica role ativo" do
      user = described_class.new(
        id: SecureRandom.uuid,
        email: "john@example.com",
        password_digest: "$2a$12$hash"
      )

      first = user.grant_role(Identity::Entities::Role::SELLER)
      second = user.grant_role(Identity::Entities::Role::SELLER)

      expect(second).to eq(first)
      expect(user.user_roles.size).to eq(1)
    end

    it "rejeita role inválido" do
      user = described_class.new(
        id: SecureRandom.uuid,
        email: "john@example.com",
        password_digest: "$2a$12$hash"
      )

      expect {
        user.grant_role("moderator")
      }.to raise_error(ArgumentError, /role_name must be one of/)
    end
  end

  describe "#revoke_role" do
    it "revoga um role adicional ativo" do
      revoked_at = Time.zone.parse("2026-05-19 10:00:00")
      admin_id = SecureRandom.uuid
      user = described_class.new(
        id: SecureRandom.uuid,
        email: "john@example.com",
        password_digest: "$2a$12$hash"
      )

      user.grant_role(Identity::Entities::Role::SELLER)
      user_role = user.revoke_role(
        Identity::Entities::Role::SELLER,
        revoked_by_user_id: admin_id,
        reason: "seller suspended",
        revoked_at: revoked_at
      )

      expect(user_role.revoked?).to be true
      expect(user_role.revoked_by_user_id).to eq(admin_id)
      expect(user.seller?).to be false
    end

    it "não permite revogar buyer" do
      user = described_class.new(
        id: SecureRandom.uuid,
        email: "john@example.com",
        password_digest: "$2a$12$hash"
      )
      user.grant_role(Identity::Entities::Role::BUYER)

      expect {
        user.revoke_role(Identity::Entities::Role::BUYER)
      }.to raise_error(ArgumentError, "buyer role cannot be revoked")
    end

    it "lança erro quando o role não está ativo" do
      user = described_class.new(
        id: SecureRandom.uuid,
        email: "john@example.com",
        password_digest: "$2a$12$hash"
      )

      expect {
        user.revoke_role(Identity::Entities::Role::SELLER)
      }.to raise_error(ArgumentError, "role is not active")
    end
  end

  describe "#active_roles" do
    it "retorna roles ativos do usuário" do
      user_id = SecureRandom.uuid
      buyer_role_id = "buyer"
      seller_role_id = "seller"

      buyer_user_role = Identity::Entities::UserRole.new(
        id: SecureRandom.uuid,
        user_id: user_id,
        role_id: buyer_role_id,
        revoked_at: nil
      )

      seller_user_role = Identity::Entities::UserRole.new(
        id: SecureRandom.uuid,
        user_id: user_id,
        role_id: seller_role_id,
        revoked_at: nil
      )

      user = described_class.new(
        id: user_id,
        email: "john@example.com",
        password_digest: "$2a$12$hash",
        user_roles: [buyer_user_role, seller_user_role]
      )

      active_roles = user.active_roles
      expect(active_roles).to contain_exactly(buyer_role_id, seller_role_id)
    end

    it "não inclui roles revogados" do
      user_id = SecureRandom.uuid
      buyer_role_id = "buyer"
      seller_role_id = "seller"

      buyer_user_role = Identity::Entities::UserRole.new(
        id: SecureRandom.uuid,
        user_id: user_id,
        role_id: buyer_role_id,
        revoked_at: nil
      )

      seller_user_role = Identity::Entities::UserRole.new(
        id: SecureRandom.uuid,
        user_id: user_id,
        role_id: seller_role_id,
        revoked_at: Time.current
      )

      user = described_class.new(
        id: user_id,
        email: "john@example.com",
        password_digest: "$2a$12$hash",
        user_roles: [buyer_user_role, seller_user_role]
      )

      active_roles = user.active_roles
      expect(active_roles).to eq([buyer_role_id])
    end
  end

  describe "#has_role?" do
    it "retorna true se user tem o role ativo" do
      user_id = SecureRandom.uuid
      buyer_user_role = Identity::Entities::UserRole.new(
        id: SecureRandom.uuid,
        user_id: user_id,
        role_id: "buyer",
        revoked_at: nil
      )

      user = described_class.new(
        id: user_id,
        email: "john@example.com",
        password_digest: "$2a$12$hash",
        user_roles: [buyer_user_role]
      )

      expect(user.has_role?("buyer")).to be true
    end

    it "retorna false se role não está atribuído" do
      user = described_class.new(
        id: SecureRandom.uuid,
        email: "john@example.com",
        password_digest: "$2a$12$hash",
        user_roles: []
      )

      expect(user.has_role?("seller")).to be false
    end

    it "retorna false se role foi revogado" do
      user_id = SecureRandom.uuid
      seller_user_role = Identity::Entities::UserRole.new(
        id: SecureRandom.uuid,
        user_id: user_id,
        role_id: "seller",
        revoked_at: Time.current
      )

      user = described_class.new(
        id: user_id,
        email: "john@example.com",
        password_digest: "$2a$12$hash",
        user_roles: [seller_user_role]
      )

      expect(user.has_role?("seller")).to be false
    end
  end

  describe "#buyer?" do
    it "retorna true se user tem role buyer ativo" do
      user_id = SecureRandom.uuid
      buyer_user_role = Identity::Entities::UserRole.new(
        id: SecureRandom.uuid,
        user_id: user_id,
        role_id: "buyer",
        revoked_at: nil
      )

      user = described_class.new(
        id: user_id,
        email: "john@example.com",
        password_digest: "$2a$12$hash",
        user_roles: [buyer_user_role]
      )

      expect(user.buyer?).to be true
    end

    it "retorna false se user não tem role buyer" do
      user = described_class.new(
        id: SecureRandom.uuid,
        email: "john@example.com",
        password_digest: "$2a$12$hash",
        user_roles: []
      )

      expect(user.buyer?).to be false
    end
  end

  describe "#seller?" do
    it "retorna true se user tem role seller ativo" do
      user_id = SecureRandom.uuid
      seller_user_role = Identity::Entities::UserRole.new(
        id: SecureRandom.uuid,
        user_id: user_id,
        role_id: "seller",
        revoked_at: nil
      )

      user = described_class.new(
        id: user_id,
        email: "john@example.com",
        password_digest: "$2a$12$hash",
        user_roles: [seller_user_role]
      )

      expect(user.seller?).to be true
    end

    it "retorna false se user não tem role seller" do
      user = described_class.new(
        id: SecureRandom.uuid,
        email: "john@example.com",
        password_digest: "$2a$12$hash",
        user_roles: []
      )

      expect(user.seller?).to be false
    end
  end

  describe "#admin?" do
    it "retorna true se user tem role platform_admin ativo" do
      user_id = SecureRandom.uuid
      admin_user_role = Identity::Entities::UserRole.new(
        id: SecureRandom.uuid,
        user_id: user_id,
        role_id: "platform_admin",
        revoked_at: nil
      )

      user = described_class.new(
        id: user_id,
        email: "john@example.com",
        password_digest: "$2a$12$hash",
        user_roles: [admin_user_role]
      )

      expect(user.admin?).to be true
    end

    it "retorna false se user não tem role platform_admin" do
      user = described_class.new(
        id: SecureRandom.uuid,
        email: "john@example.com",
        password_digest: "$2a$12$hash",
        user_roles: []
      )

      expect(user.admin?).to be false
    end
  end

  describe "#seller_profile?" do
    it "retorna true se user tem seller_profile" do
      seller_profile = Identity::Entities::SellerProfile.new(
        id: SecureRandom.uuid,
        user_id: SecureRandom.uuid,
        display_name: "John's Shop"
      )

      user = described_class.new(
        id: SecureRandom.uuid,
        email: "john@example.com",
        password_digest: "$2a$12$hash",
        seller_profile: seller_profile
      )

      expect(user.seller_profile?).to be true
    end

    it "retorna false se user não tem seller_profile" do
      user = described_class.new(
        id: SecureRandom.uuid,
        email: "john@example.com",
        password_digest: "$2a$12$hash",
        seller_profile: nil
      )

      expect(user.seller_profile?).to be false
    end
  end

  describe "constantes de status" do
    it "define todos os status válidos" do
      expect(described_class::PENDING_CONFIRMATION).to eq("pending_confirmation")
      expect(described_class::ACTIVE).to eq("active")
      expect(described_class::BLOCKED).to eq("blocked")
      expect(described_class::DEACTIVATED).to eq("deactivated")
    end

    it "VALID_STATUSES contém todos os status" do
      expect(described_class::VALID_STATUSES).to contain_exactly(
        described_class::PENDING_CONFIRMATION,
        described_class::ACTIVE,
        described_class::BLOCKED,
        described_class::DEACTIVATED
      )
    end
  end

  describe "igualdade e hash" do
    it "dois users com mesmos atributos são iguais" do
      id = SecureRandom.uuid
      user1 = described_class.new(
        id: id,
        email: "john@example.com",
        password_digest: "$2a$12$hash",
        created_at: Time.zone.parse("2026-05-17 10:00:00")
      )
      user2 = described_class.new(
        id: id,
        email: "john@example.com",
        password_digest: "$2a$12$hash",
        created_at: Time.zone.parse("2026-05-17 10:00:00")
      )

      expect(user1).to eq(user2)
      expect(user1.hash).to eq(user2.hash)
    end

    it "dois users com atributos diferentes não são iguais" do
      user1 = described_class.new(
        id: SecureRandom.uuid,
        email: "john@example.com",
        password_digest: "$2a$12$hash"
      )
      user2 = described_class.new(
        id: SecureRandom.uuid,
        email: "jane@example.com",
        password_digest: "$2a$12$hash"
      )

      expect(user1).not_to eq(user2)
    end
  end
end
