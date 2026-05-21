require "rails_helper"

RSpec.describe Identity::Services::SuspendSeller do
  class SuspendSellerInMemoryUserRepository
    attr_reader :users

    def initialize(users: [])
      @users = users.dup
    end

    def find_by_id(id)
      @users.find { |user| user.id == id }
    end

    def save(user)
      @users[@users.index { |existing| existing.id == user.id }] = user
      user
    end
  end

  class SuspendSellerInMemorySellerProfileRepository
    attr_reader :seller_profiles

    def initialize(seller_profiles: [])
      @seller_profiles = seller_profiles.dup
    end

    def find_by_id(id)
      @seller_profiles.find { |seller_profile| seller_profile.id == id }
    end

    def save(seller_profile)
      @seller_profiles[@seller_profiles.index { |existing| existing.id == seller_profile.id }] = seller_profile
      seller_profile
    end
  end

  class SuspendSellerFakeEventPublisher
    attr_reader :events

    def initialize
      @events = []
    end

    def publish(event)
      @events << event
      true
    end
  end

  let(:now) { Time.zone.parse("2026-05-20 18:00:00") }
  let(:seller_user_id) { SecureRandom.uuid }
  let(:reviewer_user_id) { SecureRandom.uuid }
  let(:seller_profile_id) { SecureRandom.uuid }
  let(:seller_user) do
    Identity::Entities::User.new(
      id: seller_user_id,
      name: "Jane Seller",
      email: "seller@example.com",
      password_digest: "hashed-password",
      status: Identity::Entities::User::ACTIVE,
      email_confirmed_at: now - 1.day,
      user_roles: [
        Identity::Entities::UserRole.new(
          user_id: seller_user_id,
          role_id: Identity::Entities::Role::SELLER,
          granted_at: now - 1.day
        )
      ]
    )
  end
  let(:reviewer) do
    Identity::Entities::User.new(
      id: reviewer_user_id,
      name: "Admin User",
      email: "admin@example.com",
      password_digest: "hashed-password",
      status: Identity::Entities::User::ACTIVE,
      email_confirmed_at: now - 1.day,
      user_roles: [
        Identity::Entities::UserRole.new(
          user_id: reviewer_user_id,
          role_id: Identity::Entities::Role::PLATFORM_ADMIN,
          granted_at: now - 1.day
        )
      ]
    )
  end
  let(:seller_profile) do
    Identity::Entities::SellerProfile.new(
      id: seller_profile_id,
      user_id: seller_user_id,
      display_name: "Jane's Crafts",
      document_type: Identity::Entities::SellerProfile::DOC_TYPE_CNPJ,
      status: Identity::Entities::SellerProfile::APPROVED,
      approved_at: now - 1.day,
      requested_at: now - 2.days
    )
  end
  let(:user_repository) { SuspendSellerInMemoryUserRepository.new(users: [ seller_user, reviewer ]) }
  let(:seller_profile_repository) do
    SuspendSellerInMemorySellerProfileRepository.new(seller_profiles: [ seller_profile ])
  end
  let(:event_publisher) { SuspendSellerFakeEventPublisher.new }

  def call_service(overrides = {})
    described_class.call(
      seller_profile_id: seller_profile_id,
      suspended_by_user_id: reviewer_user_id,
      reason: "Policy violation",
      user_repository: user_repository,
      seller_profile_repository: seller_profile_repository,
      event_publisher: event_publisher,
      clock: -> { now },
      **overrides
    )
  end

  it "suspends an approved seller profile and revokes seller role" do
    result = call_service

    expect(result).to be_success
    expect(result.seller_profile).to be_suspended
    expect(result.seller_profile.suspended_at).to eq(now)
    expect(result.seller_profile.suspension_reason).to eq("Policy violation")
    expect(result.user).not_to have_role(Identity::Entities::Role::SELLER)

    seller_role = result.user.user_roles.find { |user_role| user_role.role_id == Identity::Entities::Role::SELLER }
    expect(seller_role.revoked_at).to eq(now)
    expect(seller_role.revoked_by_user_id).to eq(reviewer_user_id)
    expect(seller_role.reason).to eq("Policy violation")
  end

  it "publishes SellerSuspended event" do
    result = call_service
    event = result.events.first

    expect(event).to be_a(Identity::Events::SellerSuspended)
    expect(event.payload).to eq(
      user_id: seller_user_id,
      seller_profile_id: seller_profile_id,
      suspension_reason: "Policy violation",
      suspended_at: now
    )
    expect(event_publisher.events).to eq(result.events)
  end

  it "requires platform_admin reviewer" do
    regular_user = Identity::Entities::User.new(
      id: reviewer_user_id,
      name: "Regular User",
      email: "regular@example.com",
      password_digest: "hashed-password",
      status: Identity::Entities::User::ACTIVE,
      email_confirmed_at: now - 1.day
    )
    user_repository = SuspendSellerInMemoryUserRepository.new(users: [ seller_user, regular_user ])

    expect {
      call_service(user_repository: user_repository)
    }.to raise_error(described_class::PermissionDenied, "reviewer must have platform_admin role")
  end

  it "requires approved seller profile" do
    seller_profile.suspend!(reason: "Policy violation", suspended_at: now - 1.minute)

    expect {
      call_service
    }.to raise_error(described_class::InvalidSellerProfileState, "seller profile must be approved")
  end

  it "requires active seller role" do
    user = Identity::Entities::User.new(
      id: seller_user_id,
      name: "Jane Seller",
      email: "seller@example.com",
      password_digest: "hashed-password",
      status: Identity::Entities::User::ACTIVE,
      email_confirmed_at: now - 1.day
    )
    user_repository = SuspendSellerInMemoryUserRepository.new(users: [ user, reviewer ])

    expect {
      call_service(user_repository: user_repository)
    }.to raise_error(described_class::SellerRoleNotActive, "seller role is not active")
  end

  it "requires a suspension reason" do
    expect {
      call_service(reason: "")
    }.to raise_error(described_class::InvalidReason, "suspension_reason cannot be nil or empty")
  end
end
