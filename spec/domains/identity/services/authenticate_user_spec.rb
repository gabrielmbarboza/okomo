require "rails_helper"

RSpec.describe Identity::Services::AuthenticateUser do
  class AuthenticateUserInMemoryUserRepository
    attr_reader :users

    def initialize(users: [])
      @users = users.dup
    end

    def find_by_email(email)
      @users.find { |user| user.email == email }
    end

    def save(user)
      existing = @users.find { |u| u.id == user.id }
      if existing
        index = @users.index(existing)
        @users[index] = user
      else
        @users << user
      end
      user
    end
  end

  class AuthenticateUserFakePasswordVerifier
    attr_reader :checks

    def initialize(matches:)
      @matches = matches
      @checks = []
    end

    def matches?(password_digest:, password:)
      @checks << { password_digest: password_digest, password: password }
      @matches
    end
  end

  class AuthenticateUserFakeAccessTokenGenerator
    attr_reader :requests

    def initialize(token:)
      @token = token
      @requests = []
    end

    def generate(user:, roles:, expires_at:)
      @requests << { user: user, roles: roles, expires_at: expires_at }
      @token
    end
  end

  class AuthenticateUserFakeEventPublisher
    attr_reader :events

    def initialize
      @events = []
    end

    def publish(event)
      @events << event
      true
    end
  end

  let(:now) { Time.zone.parse("2026-05-20 14:30:00") }
  let(:user_id) { SecureRandom.uuid }
  let(:user) do
    Identity::Entities::User.new(
      id: user_id,
      name: "Jane Doe",
      email: "jane.doe@example.com",
      password_digest: "hashed-password",
      status: Identity::Entities::User::ACTIVE,
      email_confirmed_at: now - 1.day,
      user_roles: [
        Identity::Entities::UserRole.new(
          user_id: user_id,
          role_id: Identity::Entities::Role::BUYER,
          granted_at: now - 1.day
        )
      ],
      created_at: now - 2.days,
      updated_at: now - 1.day
    )
  end
  let(:repository) { AuthenticateUserInMemoryUserRepository.new(users: [ user ]) }
  let(:password_verifier) { AuthenticateUserFakePasswordVerifier.new(matches: true) }
  let(:access_token_generator) { AuthenticateUserFakeAccessTokenGenerator.new(token: "access-token") }
  let(:event_publisher) { AuthenticateUserFakeEventPublisher.new }

  def call_service(email: " Jane.Doe@Example.com ", password: "abc12345")
    described_class.call(
      email: email,
      password: password,
      user_repository: repository,
      password_verifier: password_verifier,
      access_token_generator: access_token_generator,
      event_publisher: event_publisher,
      clock: -> { now }
    )
  end

  it "authenticates an active user with confirmed email" do
    result = call_service

    expect(result).to be_success
    expect(result.user).to eq(user)
    expect(result.access_token).to eq("access-token")
    expect(result.expires_at).to eq(now + 15.minutes)
    expect(result.roles).to eq([ Identity::Entities::Role::BUYER ])
  end

  it "normalizes email before lookup" do
    call_service

    expect(password_verifier.checks).to eq([
      { password_digest: "hashed-password", password: "abc12345" }
    ])
  end

  it "updates last_login_at and persists the user" do
    result = call_service
    saved_user = repository.find_by_email("jane.doe@example.com")

    expect(result.user.last_login_at).to eq(now)
    expect(result.user.updated_at).to eq(now)
    expect(saved_user.last_login_at).to eq(now)
  end

  it "generates an access token with user, roles and expiration" do
    call_service

    expect(access_token_generator.requests).to eq([
      {
        user: user,
        roles: [ Identity::Entities::Role::BUYER ],
        expires_at: now + 15.minutes
      }
    ])
  end

  it "publishes UserAuthenticated event without including email in the payload" do
    result = call_service
    event = result.events.first

    expect(event).to be_a(Identity::Events::UserAuthenticated)
    expect(event.payload).to eq(
      user_id: user_id,
      roles: [ Identity::Entities::Role::BUYER ],
      authenticated_at: now
    )
    expect(event.occurred_at).to eq(now)
    expect(event_publisher.events).to eq(result.events)
  end

  it "rejects unknown email with generic credentials error" do
    expect {
      call_service(email: "unknown@example.com")
    }.to raise_error(described_class::InvalidCredentials, "invalid credentials")

    expect(access_token_generator.requests).to be_empty
    expect(event_publisher.events).to be_empty
  end

  it "rejects wrong password with generic credentials error" do
    verifier = AuthenticateUserFakePasswordVerifier.new(matches: false)

    expect {
      described_class.call(
        email: user.email,
        password: "wrong-password",
        user_repository: repository,
        password_verifier: verifier,
        access_token_generator: access_token_generator,
        event_publisher: event_publisher,
        clock: -> { now }
      )
    }.to raise_error(described_class::InvalidCredentials, "invalid credentials")

    expect(access_token_generator.requests).to be_empty
    expect(event_publisher.events).to be_empty
  end

  it "requires email confirmation before authentication" do
    user = Identity::Entities::User.new(
      id: user_id,
      name: "Jane Doe",
      email: "jane.doe@example.com",
      password_digest: "hashed-password",
      status: Identity::Entities::User::PENDING_CONFIRMATION,
      email_confirmed_at: nil
    )
    repository = AuthenticateUserInMemoryUserRepository.new(users: [ user ])

    expect {
      described_class.call(
        email: user.email,
        password: "abc12345",
        user_repository: repository,
        password_verifier: password_verifier,
        access_token_generator: access_token_generator,
        event_publisher: event_publisher,
        clock: -> { now }
      )
    }.to raise_error(described_class::EmailNotConfirmed, "email must be confirmed before login")
  end

  it "rejects blocked user" do
    user = Identity::Entities::User.new(
      id: user_id,
      name: "Jane Doe",
      email: "jane.doe@example.com",
      password_digest: "hashed-password",
      status: Identity::Entities::User::BLOCKED,
      email_confirmed_at: now - 1.day
    )
    repository = AuthenticateUserInMemoryUserRepository.new(users: [ user ])

    expect {
      described_class.call(
        email: user.email,
        password: "abc12345",
        user_repository: repository,
        password_verifier: password_verifier,
        access_token_generator: access_token_generator,
        event_publisher: event_publisher,
        clock: -> { now }
      )
    }.to raise_error(described_class::UserBlocked, "user is blocked")
  end

  it "rejects deactivated user" do
    user = Identity::Entities::User.new(
      id: user_id,
      name: "Jane Doe",
      email: "jane.doe@example.com",
      password_digest: "hashed-password",
      status: Identity::Entities::User::DEACTIVATED,
      email_confirmed_at: now - 1.day
    )
    repository = AuthenticateUserInMemoryUserRepository.new(users: [ user ])

    expect {
      described_class.call(
        email: user.email,
        password: "abc12345",
        user_repository: repository,
        password_verifier: password_verifier,
        access_token_generator: access_token_generator,
        event_publisher: event_publisher,
        clock: -> { now }
      )
    }.to raise_error(described_class::UserDeactivated, "user is deactivated")
  end

  it "uses bcrypt in the default password verifier" do
    digest = BCrypt::Password.create("abc12345").to_s

    expect(described_class::BCryptPasswordVerifier.new.matches?(
      password_digest: digest,
      password: "abc12345"
    )).to be true
  end

  it "returns false from default password verifier for invalid digests" do
    expect(described_class::BCryptPasswordVerifier.new.matches?(
      password_digest: "not-a-bcrypt-digest",
      password: "abc12345"
    )).to be false
  end

  it "generates a JWT access token with minimal claims" do
    expires_at = now + described_class::ACCESS_TOKEN_TTL
    token = described_class::JwtAccessTokenGenerator.new(secret: "secret").generate(
      user: user,
      roles: [ Identity::Entities::Role::BUYER ],
      expires_at: expires_at
    )
    payload, = JWT.decode(token, "secret", true, algorithm: "HS256", verify_expiration: false)

    expect(payload).to eq(
      "sub" => user.id,
      "roles" => [ Identity::Entities::Role::BUYER ],
      "exp" => expires_at.to_i
    )
  end
end
