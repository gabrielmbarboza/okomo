require "rails_helper"

RSpec.describe Identity::Services::RegisterUser do
  class InMemoryUserRepository
    attr_reader :users

    def initialize(existing_emails: [])
      @existing_emails = existing_emails
      @users = []
    end

    def email_exists?(email)
      @existing_emails.include?(email) || @users.any? { |user| user.email == email }
    end

    def save(user)
      @users << user
      user
    end
  end

  class FakePasswordHasher
    attr_reader :passwords

    def initialize
      @passwords = []
    end

    def digest(password)
      @passwords << password
      "hashed-#{password}"
    end
  end

  class FakeConfirmationTokenGenerator
    attr_reader :requests

    def initialize(token:)
      @token = token
      @requests = []
    end

    def generate(user:, expires_at:)
      @requests << { user: user, expires_at: expires_at }
      @token
    end
  end

  class FakeConfirmationDelivery
    attr_reader :deliveries

    def initialize
      @deliveries = []
    end

    def deliver(user:, confirmation_token:)
      @deliveries << { user: user, confirmation_token: confirmation_token }
      true
    end
  end

  class FakeEventPublisher
    attr_reader :events

    def initialize
      @events = []
    end

    def publish(event)
      @events << event
      true
    end
  end

  let(:now) { Time.zone.parse("2026-05-19 10:00:00") }
  let(:repository) { InMemoryUserRepository.new }
  let(:password_hasher) { FakePasswordHasher.new }
  let(:confirmation_token) do
    Identity::ValueObjects::ConfirmationToken.new(
      raw_token: "raw-token",
      token_digest: Digest::SHA256.hexdigest("raw-token"),
      expires_at: now + described_class::CONFIRMATION_TOKEN_TTL
    )
  end
  let(:token_generator) { FakeConfirmationTokenGenerator.new(token: confirmation_token) }
  let(:confirmation_delivery) { FakeConfirmationDelivery.new }
  let(:event_publisher) { FakeEventPublisher.new }

  def call_service(email: "Jane.Doe@Example.com ", password: "abc12345", name: "Jane Doe")
    described_class.call(
      email: email,
      password: password,
      name: name,
      user_repository: repository,
      password_hasher: password_hasher,
      confirmation_token_generator: token_generator,
      confirmation_delivery: confirmation_delivery,
      event_publisher: event_publisher,
      clock: -> { now }
    )
  end

  it "cria user pendente, gera token de confirmação, envia confirmação e publica evento" do
    result = call_service
    user = result.user

    expect(result).to be_success
    expect(user).to be_a(Identity::Entities::User)
    expect(user.name).to eq("Jane Doe")
    expect(user.email).to eq("jane.doe@example.com")
    expect(user.password_digest).to eq("hashed-abc12345")
    expect(user.status).to eq(Identity::Entities::User::PENDING_CONFIRMATION)
    expect(user.email_confirmed_at).to be_nil
    expect(user.user_roles).to eq([])
    expect(user.created_at).to eq(now)
    expect(user.updated_at).to eq(now)
    expect(repository.users).to eq([ user ])
    expect(password_hasher.passwords).to eq([ "abc12345" ])
    expect(token_generator.requests).to eq([ { user: user, expires_at: now + 24.hours } ])
    expect(result.confirmation_token).to eq(confirmation_token)
    expect(confirmation_delivery.deliveries).to eq([ { user: user, confirmation_token: confirmation_token } ])
    expect(event_publisher.events).to contain_exactly(an_instance_of(Identity::Events::UserRegistered))
    expect(result.events).to eq(event_publisher.events)
  end

  it "publica UserRegistered sem carregar email no payload" do
    result = call_service
    event = result.events.first

    expect(event.payload).to eq(
      user_id: result.user.id,
      created_at: now
    )
    expect(event.occurred_at).to eq(now)
  end

  it "rejeita email inválido" do
    expect {
      call_service(email: "not-an-email")
    }.to raise_error(described_class::InvalidEmail, "email is invalid")

    expect(repository.users).to be_empty
  end

  it "rejeita email já registrado após normalização" do
    existing_repository = InMemoryUserRepository.new(existing_emails: [ "jane.doe@example.com" ])

    expect {
      described_class.call(
        email: " Jane.Doe@Example.com ",
        password: "abc12345",
        user_repository: existing_repository,
        password_hasher: password_hasher,
        confirmation_token_generator: token_generator,
        confirmation_delivery: confirmation_delivery,
        event_publisher: event_publisher,
        clock: -> { now }
      )
    }.to raise_error(described_class::EmailAlreadyRegistered, "email already registered")

    expect(existing_repository.users).to be_empty
  end

  it "rejeita senha com menos de 8 caracteres" do
    expect {
      call_service(password: "a1b2")
    }.to raise_error(described_class::WeakPassword)
  end

  it "rejeita senha sem letras" do
    expect {
      call_service(password: "12345678")
    }.to raise_error(described_class::WeakPassword)
  end

  it "rejeita senha sem números" do
    expect {
      call_service(password: "abcdefgh")
    }.to raise_error(described_class::WeakPassword)
  end

  it "gera token seguro com digest SHA256 e expiração de 24 horas por padrão" do
    generated_token = described_class::SecureConfirmationTokenGenerator.new.generate(
      user: instance_double(Identity::Entities::User),
      expires_at: now + 24.hours
    )

    expect(generated_token.raw_token).to be_present
    expect(generated_token.token_digest).to eq(Digest::SHA256.hexdigest(generated_token.raw_token))
    expect(generated_token.expires_at).to eq(now + 24.hours)
  end

  it "usa bcrypt no hasher padrão de senha" do
    digest = described_class::BCryptPasswordHasher.new.digest("abc12345")

    expect(BCrypt::Password.new(digest)).to eq("abc12345")
  end
end
