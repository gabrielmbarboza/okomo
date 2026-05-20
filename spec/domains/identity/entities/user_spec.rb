require "rails_helper"

RSpec.describe Identity::Entities::User do
  describe "#initialize" do
    context "when all parameters are valid" do
      it "creates a new user" do
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

      it "creates user with default pending_confirmation status" do
        user = described_class.new(
          id: SecureRandom.uuid,
          email: "jane@example.com",
          password_digest: "$2a$12$hash"
        )

        expect(user.status).to eq(described_class::PENDING_CONFIRMATION)
      end

      it "creates user with all optional fields filled" do
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
          user_roles: [ user_role ],
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

    context "when mandatory parameters are invalid" do
      it "raises an error if email is nil" do
        expect {
          described_class.new(
            id: SecureRandom.uuid,
            email: nil,
            password_digest: "$2a$12$hash"
          )
        }.to raise_error(ArgumentError, "email cannot be nil or empty")
      end

      it "raises an error if email is empty" do
        expect {
          described_class.new(
            id: SecureRandom.uuid,
            email: "",
            password_digest: "$2a$12$hash"
          )
        }.to raise_error(ArgumentError, "email cannot be nil or empty")
      end

      it "raises an error if password_digest is nil" do
        expect {
          described_class.new(
            id: SecureRandom.uuid,
            email: "john@example.com",
            password_digest: nil
          )
        }.to raise_error(ArgumentError, "password_digest cannot be nil or empty")
      end

      it "raises an error if status is invalid" do
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
    it "returns false if email_confirmed_at is nil" do
      user = described_class.new(
        id: SecureRandom.uuid,
        email: "john@example.com",
        password_digest: "$2a$12$hash",
        email_confirmed_at: nil
      )

      expect(user.email_confirmed?).to be false
    end

    it "returns true if email_confirmed_at is filled" do
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
    it "returns true if status is active" do
      user = described_class.new(
        id: SecureRandom.uuid,
        email: "john@example.com",
        password_digest: "$2a$12$hash",
        status: described_class::ACTIVE
      )

      expect(user.active?).to be true
    end

    it "returns false if status is not active" do
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
    it "returns true if status is blocked" do
      user = described_class.new(
        id: SecureRandom.uuid,
        email: "john@example.com",
        password_digest: "$2a$12$hash",
        status: described_class::BLOCKED
      )

      expect(user.blocked?).to be true
    end

    it "returns false if status is not blocked" do
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
    it "returns true if status is deactivated" do
      user = described_class.new(
        id: SecureRandom.uuid,
        email: "john@example.com",
        password_digest: "$2a$12$hash",
        status: described_class::DEACTIVATED
      )

      expect(user.deactivated?).to be true
    end

    it "returns false if status is not deactivated" do
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
    it "returns true if active and email is confirmed" do
      user = described_class.new(
        id: SecureRandom.uuid,
        email: "john@example.com",
        password_digest: "$2a$12$hash",
        status: described_class::ACTIVE,
        email_confirmed_at: Time.current
      )

      expect(user.can_login?).to be true
    end

    it "returns false if status is not active" do
      user = described_class.new(
        id: SecureRandom.uuid,
        email: "john@example.com",
        password_digest: "$2a$12$hash",
        status: described_class::BLOCKED,
        email_confirmed_at: Time.current
      )

      expect(user.can_login?).to be false
    end

    it "returns false if email is not confirmed" do
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

  describe "#record_login!" do
    it "updates last_login_at and updated_at" do
      logged_in_at = Time.zone.parse("2026-05-20 14:30:00")
      user = described_class.new(
        id: SecureRandom.uuid,
        email: "john@example.com",
        password_digest: "$2a$12$hash",
        status: described_class::ACTIVE,
        email_confirmed_at: logged_in_at - 1.day
      )

      result = user.record_login!(logged_in_at: logged_in_at)

      expect(result).to eq(user)
      expect(user.last_login_at).to eq(logged_in_at)
      expect(user.updated_at).to eq(logged_in_at)
    end
  end

  describe "#confirm_email!" do
    it "confirms email, activates the user and grants buyer automatically" do
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

    it "does not duplicate buyer if email was already confirmed" do
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
    it "grants a valid and auditable role" do
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

    it "does not duplicate an active role" do
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

    it "rejects an invalid role" do
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
    it "revokes an additional active role" do
      granted_at = Time.zone.parse("2026-05-18 10:00:00")
      revoked_at = Time.zone.parse("2026-05-19 10:00:00")
      admin_id = SecureRandom.uuid
      user = described_class.new(
        id: SecureRandom.uuid,
        email: "john@example.com",
        password_digest: "$2a$12$hash"
      )

      user.grant_role(Identity::Entities::Role::SELLER, granted_at: granted_at)
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

    it "does not allow revoking buyer" do
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

    it "raises an error when the role is not active" do
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
    it "returns the user's active roles" do
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
        user_roles: [ buyer_user_role, seller_user_role ]
      )

      active_roles = user.active_roles
      expect(active_roles).to contain_exactly(buyer_role_id, seller_role_id)
    end

    it "does not include revoked roles" do
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
        user_roles: [ buyer_user_role, seller_user_role ]
      )

      active_roles = user.active_roles
      expect(active_roles).to eq([ buyer_role_id ])
    end
  end

  describe "#has_role?" do
    it "returns true if the user has the active role" do
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
        user_roles: [ buyer_user_role ]
      )

      expect(user.has_role?("buyer")).to be true
    end

    it "returns false if the role is not assigned" do
      user = described_class.new(
        id: SecureRandom.uuid,
        email: "john@example.com",
        password_digest: "$2a$12$hash",
        user_roles: []
      )

      expect(user.has_role?("seller")).to be false
    end

    it "returns false if the role was revoked" do
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
        user_roles: [ seller_user_role ]
      )

      expect(user.has_role?("seller")).to be false
    end
  end

  describe "#buyer?" do
    it "returns true if the user has an active buyer role" do
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
        user_roles: [ buyer_user_role ]
      )

      expect(user.buyer?).to be true
    end

    it "returns false if the user does not have a buyer role" do
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
    it "returns true if the user has an active seller role" do
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
        user_roles: [ seller_user_role ]
      )

      expect(user.seller?).to be true
    end

    it "returns false if the user does not have a seller role" do
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
    it "returns true if the user has an active platform_admin role" do
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
        user_roles: [ admin_user_role ]
      )

      expect(user.admin?).to be true
    end

    it "returns false if the user does not have a platform_admin role" do
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
    it "returns true if the user has a seller_profile" do
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

    it "returns false if the user does not have a seller_profile" do
      user = described_class.new(
        id: SecureRandom.uuid,
        email: "john@example.com",
        password_digest: "$2a$12$hash",
        seller_profile: nil
      )

      expect(user.seller_profile?).to be false
    end
  end

  describe "status constants" do
    it "defines all valid statuses" do
      expect(described_class::PENDING_CONFIRMATION).to eq("pending_confirmation")
      expect(described_class::ACTIVE).to eq("active")
      expect(described_class::BLOCKED).to eq("blocked")
      expect(described_class::DEACTIVATED).to eq("deactivated")
    end

    it "VALID_STATUSES contains all statuses" do
      expect(described_class::VALID_STATUSES).to contain_exactly(
        described_class::PENDING_CONFIRMATION,
        described_class::ACTIVE,
        described_class::BLOCKED,
        described_class::DEACTIVATED
      )
    end
  end

  describe "equality and hash" do
    it "treats two users with the same attributes as equal" do
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

    it "does not treat two users with different attributes as equal" do
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
