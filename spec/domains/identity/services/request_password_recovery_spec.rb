require "rails_helper"

RSpec.describe Identity::Services::RequestPasswordRecovery do
  class RequestPasswordRecoveryInMemoryUserRepository
    def initialize(users: [])
      @users = users
    end

    def find_by_email(email)
      @users.find { |user| user.email == email }
    end
  end

  class RequestPasswordRecoveryFakeTokenStore
    attr_reader :stored_tokens

    def initialize
      @stored_tokens = []
    end

    def store_token(user_id, password_reset_token)
      @stored_tokens << { user_id: user_id, password_reset_token: password_reset_token }
    end
  end

  class RequestPasswordRecoveryFakeTokenGenerator
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

  class RequestPasswordRecoveryFakeDelivery
    attr_reader :deliveries

    def initialize
      @deliveries = []
    end

    def deliver(user:, password_reset_token:)
      @deliveries << { user: user, password_reset_token: password_reset_token }
      true
    end
  end

  class RequestPasswordRecoveryFakeEventPublisher
    attr_reader :events

    def initialize
      @events = []
    end

    def publish(event)
      @events << event
      true
    end
  end

  let(:now) { Time.zone.parse("2026-05-20 11:00:00") }
  let(:user) do
    Identity::Entities::User.new(
      id: SecureRandom.uuid,
      name: "Jane Doe",
      email: "jane.doe@example.com",
      password_digest: "hashed-password",
      status: Identity::Entities::User::ACTIVE,
      email_confirmed_at: now - 1.day
    )
  end
  let(:password_reset_token) do
    Identity::ValueObjects::PasswordResetToken.new(
      raw_token: "raw-reset-token",
      token_digest: Digest::SHA256.hexdigest("raw-reset-token"),
      expires_at: now + described_class::PASSWORD_RESET_TOKEN_TTL
    )
  end
  let(:repository) { RequestPasswordRecoveryInMemoryUserRepository.new(users: [ user ]) }
  let(:token_store) { RequestPasswordRecoveryFakeTokenStore.new }
  let(:token_generator) { RequestPasswordRecoveryFakeTokenGenerator.new(token: password_reset_token) }
  let(:recovery_delivery) { RequestPasswordRecoveryFakeDelivery.new }
  let(:event_publisher) { RequestPasswordRecoveryFakeEventPublisher.new }

  def call_service(email: " Jane.Doe@Example.com ")
    described_class.call(
      email: email,
      user_repository: repository,
      token_store: token_store,
      password_reset_token_generator: token_generator,
      recovery_delivery: recovery_delivery,
      event_publisher: event_publisher,
      clock: -> { now }
    )
  end

  it "generates, stores and delivers a password recovery token for an existing user" do
    result = call_service

    expect(result).to be_success
    expect(result.user).to eq(user)
    expect(result.password_reset_token).to eq(password_reset_token)
    expect(token_generator.requests).to eq([
      { user: user, expires_at: now + described_class::PASSWORD_RESET_TOKEN_TTL }
    ])
    expect(token_store.stored_tokens).to eq([
      { user_id: user.id, password_reset_token: password_reset_token }
    ])
    expect(recovery_delivery.deliveries).to eq([
      { user: user, password_reset_token: password_reset_token }
    ])
  end

  it "publishes PasswordRecoveryRequested without exposing email or raw token" do
    result = call_service
    event = result.events.first

    expect(event).to be_a(Identity::Events::PasswordRecoveryRequested)
    expect(event.payload).to eq(user_id: user.id, requested_at: now)
    expect(event.payload.values).not_to include(user.email, password_reset_token.raw_token)
    expect(event_publisher.events).to eq(result.events)
  end

  it "returns success without side effects when the email is unknown" do
    result = call_service(email: "unknown@example.com")

    expect(result).to be_success
    expect(result.user).to be_nil
    expect(result.password_reset_token).to be_nil
    expect(result.events).to eq([])
    expect(token_generator.requests).to be_empty
    expect(token_store.stored_tokens).to be_empty
    expect(recovery_delivery.deliveries).to be_empty
    expect(event_publisher.events).to be_empty
  end

  it "generates a secure reset token with SHA256 digest and a 2-hour expiration" do
    generated_token = described_class::SecurePasswordResetTokenGenerator.new.generate(
      user: user,
      expires_at: now + described_class::PASSWORD_RESET_TOKEN_TTL
    )

    expect(generated_token.raw_token).to be_present
    expect(generated_token.token_digest).to eq(Digest::SHA256.hexdigest(generated_token.raw_token))
    expect(generated_token.expires_at).to eq(now + 2.hours)
    expect(generated_token.used_at).to be_nil
  end
end
