require "rails_helper"

RSpec.describe Identity::Services::ReactivateSeller do
  class ReactivateSellerInMemoryUserRepository
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

  class ReactivateSellerInMemorySellerProfileRepository
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

  class ReactivateSellerFakeEventPublisher
    attr_reader :events

    def initialize
      @events = []
    end

    def publish(event)
      @events << event
      true
    end
  end

  let(:now) { Time.zone.parse("2026-05-20 19:00:00") }
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
      email_confirmed_at: now - 2.days,
      user_roles: [
        Identity::Entities::UserRole.new(
          user_id: seller_user_id,
          role_id: Identity::Entities::Role::SELLER,
          granted_at: now - 2.days,
          revoked_at: now - 1.day,
          revoked_by_user_id: reviewer_user_id,
          reason: "Policy violation"
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
      email_confirmed_at: now - 2.days,
      user_roles: [
        Identity::Entities::UserRole.new(
          user_id: reviewer_user_id,
          role_id: Identity::Entities::Role::PLATFORM_ADMIN,
          granted_at: now - 2.days
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
      status: Identity::Entities::SellerProfile::SUSPENDED,
      approved_at: now - 3.days,
      suspended_at: now - 1.day,
      suspension_reason: "Policy violation",
      requested_at: now - 4.days
    )
  end
  let(:user_repository) { ReactivateSellerInMemoryUserRepository.new(users: [ seller_user, reviewer ]) }
  let(:seller_profile_repository) do
    ReactivateSellerInMemorySellerProfileRepository.new(seller_profiles: [ seller_profile ])
  end
  let(:event_publisher) { ReactivateSellerFakeEventPublisher.new }

  def call_service(overrides = {})
    described_class.call(
      seller_profile_id: seller_profile_id,
      reactivated_by_user_id: reviewer_user_id,
      reason: "Policy issue resolved",
      user_repository: user_repository,
      seller_profile_repository: seller_profile_repository,
      event_publisher: event_publisher,
      clock: -> { now },
      **overrides
    )
  end

  it "reactivates a suspended seller profile and grants a new seller role" do
    result = call_service

    expect(result).to be_success
    expect(result.seller_profile).to be_approved
    expect(result.seller_profile.suspended_at).to be_nil
    expect(result.seller_profile.suspension_reason).to be_nil
    expect(result.user).to have_role(Identity::Entities::Role::SELLER)

    seller_roles = result.user.user_roles.select { |user_role| user_role.role_id == Identity::Entities::Role::SELLER }
    new_seller_role = seller_roles.last
    expect(seller_roles.size).to eq(2)
    expect(new_seller_role.granted_at).to eq(now)
    expect(new_seller_role.granted_by_user_id).to eq(reviewer_user_id)
    expect(new_seller_role.reason).to eq("Policy issue resolved")
  end

  it "publishes SellerReactivated event" do
    result = call_service
    event = result.events.first

    expect(event).to be_a(Identity::Events::SellerReactivated)
    expect(event.payload).to eq(
      user_id: seller_user_id,
      seller_profile_id: seller_profile_id,
      reactivated_by_user_id: reviewer_user_id,
      reactivated_at: now
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
    user_repository = ReactivateSellerInMemoryUserRepository.new(users: [ seller_user, regular_user ])

    expect {
      call_service(user_repository: user_repository)
    }.to raise_error(described_class::PermissionDenied, "reviewer must have platform_admin role")
  end

  it "requires reviewer admin role to be effective" do
    blocked_reviewer = Identity::Entities::User.new(
      id: reviewer_user_id,
      name: "Blocked Admin",
      email: "admin@example.com",
      password_digest: "hashed-password",
      status: Identity::Entities::User::BLOCKED,
      email_confirmed_at: now - 1.day,
      user_roles: [
        Identity::Entities::UserRole.new(
          user_id: reviewer_user_id,
          role_id: Identity::Entities::Role::PLATFORM_ADMIN
        )
      ]
    )
    user_repository = ReactivateSellerInMemoryUserRepository.new(users: [ seller_user, blocked_reviewer ])

    expect {
      call_service(user_repository: user_repository)
    }.to raise_error(described_class::PermissionDenied, "reviewer must have platform_admin role")
  end

  it "requires suspended seller profile" do
    seller_profile.reactivate!(reactivated_at: now - 1.minute)

    expect {
      call_service
    }.to raise_error(described_class::InvalidSellerProfileState, "seller profile must be suspended")
  end

  it "requires seller role to be inactive" do
    user = Identity::Entities::User.new(
      id: seller_user_id,
      name: "Jane Seller",
      email: "seller@example.com",
      password_digest: "hashed-password",
      status: Identity::Entities::User::ACTIVE,
      email_confirmed_at: now - 2.days,
      user_roles: [
        Identity::Entities::UserRole.new(
          user_id: seller_user_id,
          role_id: Identity::Entities::Role::SELLER,
          granted_at: now - 2.days
        )
      ]
    )
    user_repository = ReactivateSellerInMemoryUserRepository.new(users: [ user, reviewer ])

    expect {
      call_service(user_repository: user_repository)
    }.to raise_error(described_class::SellerRoleAlreadyActive, "seller role is already active")
  end

  it "requires a reactivation reason" do
    expect {
      call_service(reason: "")
    }.to raise_error(described_class::InvalidReason, "reactivation_reason cannot be nil or empty")
  end

  it "raises when seller profile is not found" do
    expect {
      call_service(seller_profile_id: SecureRandom.uuid)
    }.to raise_error(described_class::SellerProfileNotFound, "seller profile not found")
  end
end
