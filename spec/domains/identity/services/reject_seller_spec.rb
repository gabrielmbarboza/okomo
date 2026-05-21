require "rails_helper"

RSpec.describe Identity::Services::RejectSeller do
  class RejectSellerInMemoryUserRepository
    def initialize(users: [])
      @users = users.dup
    end

    def find_by_id(id)
      @users.find { |user| user.id == id }
    end
  end

  class RejectSellerInMemorySellerProfileRepository
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

  class RejectSellerFakeEventPublisher
    attr_reader :events

    def initialize
      @events = []
    end

    def publish(event)
      @events << event
      true
    end
  end

  let(:now) { Time.zone.parse("2026-05-20 17:00:00") }
  let(:seller_user_id) { SecureRandom.uuid }
  let(:reviewer_user_id) { SecureRandom.uuid }
  let(:seller_profile_id) { SecureRandom.uuid }
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
      status: Identity::Entities::SellerProfile::PENDING_REVIEW,
      requested_at: now - 1.hour
    )
  end
  let(:user_repository) { RejectSellerInMemoryUserRepository.new(users: [ reviewer ]) }
  let(:seller_profile_repository) do
    RejectSellerInMemorySellerProfileRepository.new(seller_profiles: [ seller_profile ])
  end
  let(:event_publisher) { RejectSellerFakeEventPublisher.new }

  def call_service(overrides = {})
    described_class.call(
      seller_profile_id: seller_profile_id,
      reviewed_by_user_id: reviewer_user_id,
      reason: "Missing required tax documentation",
      user_repository: user_repository,
      seller_profile_repository: seller_profile_repository,
      event_publisher: event_publisher,
      clock: -> { now },
      **overrides
    )
  end

  it "rejects a pending seller profile with a reason" do
    result = call_service

    expect(result).to be_success
    expect(result.seller_profile).to be_rejected
    expect(result.seller_profile.rejected_at).to eq(now)
    expect(result.seller_profile.reviewed_at).to eq(now)
    expect(result.seller_profile.reviewed_by_user_id).to eq(reviewer_user_id)
    expect(result.seller_profile.rejection_reason).to eq("Missing required tax documentation")
  end

  it "publishes SellerRejected event" do
    result = call_service
    event = result.events.first

    expect(event).to be_a(Identity::Events::SellerRejected)
    expect(event.payload).to eq(
      user_id: seller_user_id,
      seller_profile_id: seller_profile_id,
      reviewed_by_user_id: reviewer_user_id,
      rejection_reason: "Missing required tax documentation",
      rejected_at: now
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
    user_repository = RejectSellerInMemoryUserRepository.new(users: [ regular_user ])

    expect {
      call_service(user_repository: user_repository)
    }.to raise_error(described_class::PermissionDenied, "reviewer must have platform_admin role")
  end

  it "requires pending seller profile" do
    seller_profile.reject!(
      reviewed_by_user_id: reviewer_user_id,
      reason: "Missing required tax documentation",
      reviewed_at: now - 1.minute
    )

    expect {
      call_service
    }.to raise_error(described_class::InvalidSellerProfileState, "seller profile must be pending_review")
  end

  it "requires a rejection reason" do
    expect {
      call_service(reason: "")
    }.to raise_error(described_class::InvalidReason, "rejection_reason cannot be nil or empty")
  end
end
