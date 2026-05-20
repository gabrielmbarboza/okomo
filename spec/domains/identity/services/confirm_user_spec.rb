require "rails_helper"

RSpec.describe Identity::Services::ConfirmUser do
  class ConfirmUserInMemoryUserRepository
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
        index = @users.index(existing)
        @users[index] = user
      else
        @users << user
      end
      user
    end
  end

  class ConfirmUserFakeTokenStore
    def initialize
      @tokens = {}
    end

    def store_token(user_id, confirmation_token)
      @tokens[user_id] = confirmation_token
    end

    def get_token(user_id)
      @tokens[user_id]
    end

    def delete_token(user_id)
      @tokens.delete(user_id)
    end
  end

  class ConfirmUserFakeEventPublisher
    attr_reader :events

    def initialize
      @events = []
    end

    def publish(event)
      @events << event
      true
    end
  end

  let(:now) { Time.zone.parse("2026-05-20 10:00:00") }
  let(:user_id) { SecureRandom.uuid }
  let(:confirmation_token) do
    Identity::ValueObjects::ConfirmationToken.new(
      raw_token: "valid-token-123",
      token_digest: Digest::SHA256.hexdigest("valid-token-123"),
      expires_at: now + 24.hours
    )
  end
  let(:repository) do
    user = Identity::Entities::User.new(
      id: user_id,
      name: "Test User",
      email: "test@example.com",
      password_digest: "hashed-password",
      status: Identity::Entities::User::PENDING_CONFIRMATION,
      email_confirmed_at: nil,
      created_at: now - 1.hour,
      updated_at: now - 1.hour
    )
    ConfirmUserInMemoryUserRepository.new(users: [user])
  end
  let(:token_store) { ConfirmUserFakeTokenStore.new }
  let(:event_publisher) { ConfirmUserFakeEventPublisher.new }

  before do
    token_store.store_token(user_id, confirmation_token)
  end

  subject do
    described_class.new(
      user_id: user_id,
      raw_token: confirmation_token.raw_token,
      user_repository: repository,
      token_store: token_store,
      event_publisher: event_publisher,
      clock: -> { now }
    )
  end

  describe ".call" do
    context "when token is valid and not expired" do
      it "confirms user email" do
        result = subject.call

        expect(result.success?).to be true
        expect(result.user.email_confirmed?).to be true
      end

      it "transitions user to active status" do
        result = subject.call

        expect(result.user.active?).to be true
      end

      it "grants buyer role automatically" do
        result = subject.call

        expect(result.user.has_role?(Identity::Entities::Role::BUYER)).to be true
      end

      it "sets email_confirmed_at timestamp" do
        result = subject.call

        expect(result.user.email_confirmed_at).to eq(now)
      end

      it "saves user to repository" do
        result = subject.call
        saved_user = repository.find_by_id(user_id)

        expect(saved_user.email_confirmed_at).to eq(now)
        expect(saved_user.active?).to be true
      end

      it "publishes UserEmailConfirmed event" do
        result = subject.call

        expect(result.events.count).to eq(1)
        event = result.events.first
        expect(event).to be_a(Identity::Events::UserEmailConfirmed)
        expect(event.payload[:user_id]).to eq(user_id)
      end

      it "returns result with success flag" do
        result = subject.call

        expect(result.success?).to be true
        expect(result.user).to be_a(Identity::Entities::User)
        expect(result.events).to be_an(Array)
      end

      it "deletes confirmation token from store" do
        subject.call

        expect(token_store.get_token(user_id)).to be_nil
      end

      it "user can login after email confirmation" do
        result = subject.call

        expect(result.user.can_login?).to be true
      end
    end

    context "when token is expired" do
      let(:confirmation_token) do
        Identity::ValueObjects::ConfirmationToken.new(
          raw_token: "expired-token",
          token_digest: Digest::SHA256.hexdigest("expired-token"),
          expires_at: now - 1.hour
        )
      end

      before do
        token_store.delete_token(user_id)
        token_store.store_token(user_id, confirmation_token)
      end

      it "raises TokenExpired error" do
        expect { subject.call }.to raise_error(
          described_class::TokenExpired,
          /confirmation token has expired/
        )
      end

      it "does not confirm user email" do
        expect { subject.call }.to raise_error(described_class::TokenExpired)
        user = repository.find_by_id(user_id)
        expect(user.email_confirmed?).to be false
      end
    end

    context "when token is invalid" do
      subject do
        described_class.new(
          user_id: user_id,
          raw_token: "invalid-token",
          user_repository: repository,
          token_store: token_store,
          event_publisher: event_publisher,
          clock: -> { now }
        )
      end

      it "raises InvalidToken error" do
        expect { subject.call }.to raise_error(
          described_class::InvalidToken,
          /confirmation token is invalid/
        )
      end

      it "does not confirm user email" do
        expect { subject.call }.to raise_error(described_class::InvalidToken)
        user = repository.find_by_id(user_id)
        expect(user.email_confirmed?).to be false
      end
    end

    context "when user not found" do
      let(:invalid_user_id) { SecureRandom.uuid }

      subject do
        described_class.new(
          user_id: invalid_user_id,
          raw_token: confirmation_token.raw_token,
          user_repository: repository,
          token_store: token_store,
          event_publisher: event_publisher,
          clock: -> { now }
        )
      end

      it "raises UserNotFound error" do
        expect { subject.call }.to raise_error(
          described_class::UserNotFound,
          /user not found/
        )
      end
    end

    context "when token not found for user" do
      before do
        token_store.delete_token(user_id)
      end

      it "raises InvalidToken error" do
        expect { subject.call }.to raise_error(
          described_class::InvalidToken,
          /confirmation token is invalid/
        )
      end
    end

    context "when user already has email confirmed" do
      let(:repository) do
        user = Identity::Entities::User.new(
          id: user_id,
          name: "Test User",
          email: "test@example.com",
          password_digest: "hashed-password",
          status: Identity::Entities::User::ACTIVE,
          email_confirmed_at: now - 1.hour,
          created_at: now - 2.hours,
          updated_at: now - 1.hour
        )
        ConfirmUserInMemoryUserRepository.new(users: [user])
      end

      it "raises UserAlreadyConfirmed error" do
        expect { subject.call }.to raise_error(
          described_class::UserAlreadyConfirmed,
          /user email already confirmed/
        )
      end
    end

    context "when multiple confirm attempts are made" do
      it "only first confirmation succeeds" do
        result = subject.call
        expect(result.success?).to be true

        expect { subject.call }.to raise_error(
          described_class::UserAlreadyConfirmed
        )
      end
    end
  end
end
