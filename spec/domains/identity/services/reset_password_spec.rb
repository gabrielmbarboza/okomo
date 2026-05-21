require "rails_helper"

RSpec.describe Identity::Services::ResetPassword do
  class ResetPasswordInMemoryUserRepository
    attr_reader :users

    def initialize(users: [])
      @users = users.dup
    end

    def find_by_id(id)
      @users.find { |user| user.id == id }
    end

    def save(user)
      existing = @users.find { |u| u.id == user.id }
      if existing
        @users[@users.index(existing)] = user
      else
        @users << user
      end
      user
    end
  end

  class ResetPasswordFakeTokenStore
    attr_reader :used_tokens

    def initialize(tokens: {})
      @tokens = tokens
      @used_tokens = []
    end

    def find_token(user_id:, token_digest:)
      @tokens[[ user_id, token_digest ]]
    end

    def mark_token_used(user_id:, token_digest:, used_at:)
      @used_tokens << { user_id: user_id, token_digest: token_digest, used_at: used_at }
    end
  end

  class ResetPasswordFakePasswordHasher
    attr_reader :passwords

    def initialize
      @passwords = []
    end

    def digest(password)
      @passwords << password
      "hashed-#{password}"
    end
  end

  class ResetPasswordFakeEventPublisher
    attr_reader :events

    def initialize
      @events = []
    end

    def publish(event)
      @events << event
      true
    end
  end

  let(:now) { Time.zone.parse("2026-05-20 12:00:00") }
  let(:user_id) { SecureRandom.uuid }
  let(:raw_token) { "valid-reset-token" }
  let(:token_digest) { Digest::SHA256.hexdigest(raw_token) }
  let(:password_reset_token) do
    Identity::ValueObjects::PasswordResetToken.new(
      raw_token: raw_token,
      token_digest: token_digest,
      expires_at: now + 1.hour
    )
  end
  let(:user) do
    Identity::Entities::User.new(
      id: user_id,
      name: "Jane Doe",
      email: "jane.doe@example.com",
      password_digest: "old-hash",
      status: Identity::Entities::User::ACTIVE,
      email_confirmed_at: now - 1.day,
      updated_at: now - 1.day
    )
  end
  let(:repository) { ResetPasswordInMemoryUserRepository.new(users: [ user ]) }
  let(:token_store) { ResetPasswordFakeTokenStore.new(tokens: { [ user_id, token_digest ] => password_reset_token }) }
  let(:password_hasher) { ResetPasswordFakePasswordHasher.new }
  let(:event_publisher) { ResetPasswordFakeEventPublisher.new }

  def call_service(new_password: "newpass123", token: raw_token)
    described_class.call(
      user_id: user_id,
      raw_token: token,
      new_password: new_password,
      user_repository: repository,
      token_store: token_store,
      password_hasher: password_hasher,
      event_publisher: event_publisher,
      clock: -> { now }
    )
  end

  it "resets the password, marks the token as used and publishes an event" do
    result = call_service

    expect(result).to be_success
    expect(result.user.password_digest).to eq("hashed-newpass123")
    expect(result.user.updated_at).to eq(now)
    expect(repository.find_by_id(user_id).password_digest).to eq("hashed-newpass123")
    expect(password_hasher.passwords).to eq([ "newpass123" ])
    expect(token_store.used_tokens).to eq([
      { user_id: user_id, token_digest: token_digest, used_at: now }
    ])

    event = result.events.first
    expect(event).to be_a(Identity::Events::PasswordResetCompleted)
    expect(event.payload).to eq(user_id: user_id, reset_at: now)
    expect(event_publisher.events).to eq(result.events)
  end

  it "rejects an invalid token" do
    expect {
      call_service(token: "wrong-token")
    }.to raise_error(described_class::InvalidToken, "password reset token is invalid")

    expect(password_hasher.passwords).to be_empty
    expect(token_store.used_tokens).to be_empty
  end

  it "rejects an expired token" do
    expired_token = Identity::ValueObjects::PasswordResetToken.new(
      raw_token: raw_token,
      token_digest: token_digest,
      expires_at: now - 1.minute
    )
    token_store = ResetPasswordFakeTokenStore.new(tokens: { [ user_id, token_digest ] => expired_token })

    expect {
      described_class.call(
        user_id: user_id,
        raw_token: raw_token,
        new_password: "newpass123",
        user_repository: repository,
        token_store: token_store,
        password_hasher: password_hasher,
        event_publisher: event_publisher,
        clock: -> { now }
      )
    }.to raise_error(described_class::TokenExpired, "password reset token has expired")
  end

  it "rejects a token that was already used" do
    used_token = Identity::ValueObjects::PasswordResetToken.new(
      raw_token: raw_token,
      token_digest: token_digest,
      expires_at: now + 1.hour,
      used_at: now - 1.minute
    )
    token_store = ResetPasswordFakeTokenStore.new(tokens: { [ user_id, token_digest ] => used_token })

    expect {
      described_class.call(
        user_id: user_id,
        raw_token: raw_token,
        new_password: "newpass123",
        user_repository: repository,
        token_store: token_store,
        password_hasher: password_hasher,
        event_publisher: event_publisher,
        clock: -> { now }
      )
    }.to raise_error(described_class::TokenAlreadyUsed, "password reset token was already used")
  end

  it "rejects a weak password" do
    expect {
      call_service(new_password: "short1")
    }.to raise_error(described_class::WeakPassword)

    expect(password_hasher.passwords).to be_empty
    expect(token_store.used_tokens).to be_empty
  end

  it "raises when user is not found" do
    repository = ResetPasswordInMemoryUserRepository.new(users: [])

    expect {
      described_class.call(
        user_id: user_id,
        raw_token: raw_token,
        new_password: "newpass123",
        user_repository: repository,
        token_store: token_store,
        password_hasher: password_hasher,
        event_publisher: event_publisher,
        clock: -> { now }
      )
    }.to raise_error(described_class::UserNotFound, "user not found")
  end

  it "uses bcrypt in the default password hasher" do
    digest = described_class::BCryptPasswordHasher.new.digest("newpass123")

    expect(BCrypt::Password.new(digest)).to eq("newpass123")
  end
end
