require "rails_helper"

RSpec.describe Identity::Services::RequestSellerApplication do
  class RequestSellerApplicationInMemoryUserRepository
    def initialize(users: [])
      @users = users
    end

    def find_by_id(id)
      @users.find { |user| user.id == id }
    end
  end

  class RequestSellerApplicationInMemorySellerProfileRepository
    attr_reader :seller_profiles

    def initialize(seller_profiles: [])
      @seller_profiles = seller_profiles.dup
    end

    def active_or_pending_for_user?(user_id)
      @seller_profiles.any? do |seller_profile|
        seller_profile.user_id == user_id &&
          (seller_profile.pending_review? || seller_profile.approved? || seller_profile.suspended?)
      end
    end

    def save(seller_profile)
      @seller_profiles << seller_profile
      seller_profile
    end
  end

  class RequestSellerApplicationFakeEventPublisher
    attr_reader :events

    def initialize
      @events = []
    end

    def publish(event)
      @events << event
      true
    end
  end

  let(:now) { Time.zone.parse("2026-05-20 15:00:00") }
  let(:user_id) { SecureRandom.uuid }
  let(:user) do
    Identity::Entities::User.new(
      id: user_id,
      name: "Jane Doe",
      email: "jane.doe@example.com",
      password_digest: "hashed-password",
      status: Identity::Entities::User::ACTIVE,
      email_confirmed_at: now - 1.day
    )
  end
  let(:user_repository) { RequestSellerApplicationInMemoryUserRepository.new(users: [ user ]) }
  let(:seller_profile_repository) { RequestSellerApplicationInMemorySellerProfileRepository.new }
  let(:event_publisher) { RequestSellerApplicationFakeEventPublisher.new }
  let(:commercial_address) do
    {
      "street" => "Rua das Flores",
      "number" => "123",
      "complement" => "Sala 2",
      "city" => "Sao Paulo",
      "state" => "SP",
      "zip_code" => "01310-100"
    }
  end

  def call_service(overrides = {})
    params = {
      user_id: user_id,
      display_name: "Jane's Crafts",
      description: "Ceramic pieces made by hand",
      document_type: Identity::Entities::SellerProfile::DOC_TYPE_CNPJ,
      document_number: "12.345.678/0001-95",
      legal_name: "Jane Crafts LTDA",
      contact_email: "store@example.com",
      contact_phone: "+55 11 98765-4321",
      commercial_address: commercial_address,
      user_repository: user_repository,
      seller_profile_repository: seller_profile_repository,
      event_publisher: event_publisher,
      clock: -> { now }
    }.merge(overrides)

    described_class.call(**params)
  end

  it "creates a pending seller profile for an active confirmed user" do
    result = call_service
    seller_profile = result.seller_profile

    expect(result).to be_success
    expect(seller_profile).to be_a(Identity::Entities::SellerProfile)
    expect(seller_profile.user_id).to eq(user_id)
    expect(seller_profile.display_name).to eq("Jane's Crafts")
    expect(seller_profile.description).to eq("Ceramic pieces made by hand")
    expect(seller_profile.status).to eq(Identity::Entities::SellerProfile::PENDING_REVIEW)
    expect(seller_profile.document_type).to eq(Identity::Entities::SellerProfile::DOC_TYPE_CNPJ)
    expect(seller_profile.document_number).to eq("12345678000195")
    expect(seller_profile.legal_name).to eq("Jane Crafts LTDA")
    expect(seller_profile.contact_email).to eq("store@example.com")
    expect(seller_profile.contact_phone).to eq("+55 11 98765-4321")
    expect(seller_profile.commercial_address).to eq(commercial_address)
    expect(seller_profile.requested_at).to eq(now)
    expect(seller_profile.created_at).to eq(now)
    expect(seller_profile.updated_at).to eq(now)
    expect(seller_profile_repository.seller_profiles).to eq([ seller_profile ])
    expect(user).not_to have_role(Identity::Entities::Role::SELLER)
  end

  it "publishes SellerApplicationSubmitted without exposing document number" do
    result = call_service
    event = result.events.first

    expect(event).to be_a(Identity::Events::SellerApplicationSubmitted)
    expect(event.payload).to eq(
      user_id: user_id,
      seller_profile_id: result.seller_profile.id,
      display_name: "Jane's Crafts",
      document_type: Identity::Entities::SellerProfile::DOC_TYPE_CNPJ,
      requested_at: now
    )
    expect(event.payload.values).not_to include("12345678000195", "12.345.678/0001-95")
    expect(event_publisher.events).to eq(result.events)
  end

  it "raises when user is not found" do
    expect {
      call_service(user_id: SecureRandom.uuid)
    }.to raise_error(described_class::UserNotFound, "user not found")
  end

  it "requires an active confirmed user" do
    user = Identity::Entities::User.new(
      id: user_id,
      name: "Jane Doe",
      email: "jane.doe@example.com",
      password_digest: "hashed-password",
      status: Identity::Entities::User::PENDING_CONFIRMATION,
      email_confirmed_at: nil
    )
    user_repository = RequestSellerApplicationInMemoryUserRepository.new(users: [ user ])

    expect {
      call_service(user_repository: user_repository)
    }.to raise_error(described_class::UserNotAllowed, "user must be active and email confirmed")
  end

  it "rejects blocked users" do
    user = Identity::Entities::User.new(
      id: user_id,
      name: "Jane Doe",
      email: "jane.doe@example.com",
      password_digest: "hashed-password",
      status: Identity::Entities::User::BLOCKED,
      email_confirmed_at: now - 1.day
    )
    user_repository = RequestSellerApplicationInMemoryUserRepository.new(users: [ user ])

    expect {
      call_service(user_repository: user_repository)
    }.to raise_error(described_class::UserNotAllowed, "user must be active and email confirmed")
  end

  it "rejects users with an active or pending seller profile" do
    existing_seller_profile = Identity::Entities::SellerProfile.new(
      user_id: user_id,
      display_name: "Existing Shop",
      document_type: Identity::Entities::SellerProfile::DOC_TYPE_CPF
    )
    seller_profile_repository = RequestSellerApplicationInMemorySellerProfileRepository.new(
      seller_profiles: [ existing_seller_profile ]
    )

    expect {
      call_service(seller_profile_repository: seller_profile_repository)
    }.to raise_error(described_class::SellerProfileAlreadyExists, "user already has an active or pending seller profile")
  end

  it "allows a new application when previous profile was rejected" do
    rejected_seller_profile = Identity::Entities::SellerProfile.new(
      user_id: user_id,
      display_name: "Rejected Shop",
      document_type: Identity::Entities::SellerProfile::DOC_TYPE_CPF,
      status: Identity::Entities::SellerProfile::REJECTED
    )
    seller_profile_repository = RequestSellerApplicationInMemorySellerProfileRepository.new(
      seller_profiles: [ rejected_seller_profile ]
    )

    result = call_service(seller_profile_repository: seller_profile_repository)

    expect(result.seller_profile).to be_pending_review
    expect(seller_profile_repository.seller_profiles).to eq([ rejected_seller_profile, result.seller_profile ])
  end

  it "rejects invalid document types" do
    expect {
      call_service(document_type: "passport")
    }.to raise_error(described_class::InvalidDocument, "document_type must be one of: cpf, cnpj, mei")
  end

  it "rejects invalid document numbers" do
    expect {
      call_service(
        document_type: Identity::Entities::SellerProfile::DOC_TYPE_CPF,
        document_number: "123"
      )
    }.to raise_error(described_class::InvalidDocument, "document_number is invalid for cpf")
  end

  it "requires commercial contact data" do
    expect {
      call_service(display_name: "")
    }.to raise_error(described_class::InvalidSellerApplication, "display_name cannot be nil or empty")

    expect {
      call_service(contact_email: "not-an-email")
    }.to raise_error(described_class::InvalidSellerApplication, "contact_email is invalid")
  end

  it "requires mandatory address fields" do
    address = commercial_address.merge("zip_code" => "")

    expect {
      call_service(commercial_address: address)
    }.to raise_error(described_class::InvalidSellerApplication, "commercial_address.zip_code cannot be nil or empty")
  end
end
