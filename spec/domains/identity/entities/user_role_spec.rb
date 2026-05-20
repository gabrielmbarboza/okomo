require "rails_helper"

RSpec.describe Identity::Entities::UserRole do
  describe "#initialize" do
    context "when all parameters are valid" do
      it "creates an active user_role" do
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

      it "creates a revoked user_role" do
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

      it "predefines granted_at, created_at and updated_at with current timestamp" do
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

      it "accepts optional parameters as nil" do
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

    context "when mandatory parameters are invalid" do
      it "raises an error if user_id is nil" do
        expect {
          described_class.new(
            id: SecureRandom.uuid,
            user_id: nil,
            role_id: SecureRandom.uuid
          )
        }.to raise_error(ArgumentError, "user_id cannot be nil")
      end

      it "raises an error if role_id is nil" do
        expect {
          described_class.new(
            id: SecureRandom.uuid,
            user_id: SecureRandom.uuid,
            role_id: nil
          )
        }.to raise_error(ArgumentError, "role_id cannot be nil")
      end

      it "raises an error if revoked_at is before granted_at" do
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
    it "returns true if revoked_at is nil" do
      user_role = described_class.new(
        id: SecureRandom.uuid,
        user_id: SecureRandom.uuid,
        role_id: SecureRandom.uuid,
        revoked_at: nil
      )

      expect(user_role.active?).to be true
    end

    it "returns false if revoked_at is filled" do
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
    it "returns false if revoked_at is nil" do
      user_role = described_class.new(
        id: SecureRandom.uuid,
        user_id: SecureRandom.uuid,
        role_id: SecureRandom.uuid,
        revoked_at: nil
      )

      expect(user_role.revoked?).to be false
    end

    it "returns true if revoked_at is filled" do
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
    it "returns true for buyer role" do
      user_role = described_class.new(
        id: SecureRandom.uuid,
        user_id: SecureRandom.uuid,
        role_id: Identity::Entities::Role::BUYER
      )

      expect(user_role.buyer?).to be true
    end

    it "returns false for other roles" do
      user_role = described_class.new(
        id: SecureRandom.uuid,
        user_id: SecureRandom.uuid,
        role_id: Identity::Entities::Role::SELLER
      )

      expect(user_role.buyer?).to be false
    end
  end

  describe "#revoke!" do
    it "revokes an active role and preserves audit data" do
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

    it "does not allow revoking buyer" do
      user_role = described_class.new(
        id: SecureRandom.uuid,
        user_id: SecureRandom.uuid,
        role_id: Identity::Entities::Role::BUYER
      )

      expect {
        user_role.revoke!(reason: "not allowed")
      }.to raise_error(ArgumentError, "buyer role cannot be revoked")
    end

    it "does not allow revoking twice" do
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
    it "calculates time elapsed since grant" do
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

    it "returns approximately 0 for recent grant" do
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
    it "returns nil if role was not revoked" do
      user_role = described_class.new(
        id: SecureRandom.uuid,
        user_id: SecureRandom.uuid,
        role_id: SecureRandom.uuid,
        revoked_at: nil
      )

      expect(user_role.revoked_ago).to be_nil
    end

    it "calculates time elapsed since revocation" do
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
    it "returns duration from grant to revocation" do
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

    it "returns duration from grant to now if not revoked" do
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

    it "returns small duration if grant is recent" do
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

  describe "audit" do
    it "tracks who granted the role" do
      admin_id = SecureRandom.uuid
      user_role = described_class.new(
        id: SecureRandom.uuid,
        user_id: SecureRandom.uuid,
        role_id: SecureRandom.uuid,
        granted_by_user_id: admin_id
      )

      expect(user_role.granted_by_user_id).to eq(admin_id)
    end

    it "tracks who revoked the role" do
      admin_id = SecureRandom.uuid
      user_role = described_class.new(
        id: SecureRandom.uuid,
        user_id: SecureRandom.uuid,
        role_id: SecureRandom.uuid,
        revoked_by_user_id: admin_id
      )

      expect(user_role.revoked_by_user_id).to eq(admin_id)
    end

    it "records reason for grant or revocation" do
      reason = "approved seller application #12345"
      user_role = described_class.new(
        id: SecureRandom.uuid,
        user_id: SecureRandom.uuid,
        role_id: SecureRandom.uuid,
        reason: reason
      )

      expect(user_role.reason).to eq(reason)
    end

    it "maintains complete and immutable history" do
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

  describe "equality and hash" do
    it "treats two user_roles with the same attributes as equal" do
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

    it "does not treat two user_roles with different attributes as equal" do
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
