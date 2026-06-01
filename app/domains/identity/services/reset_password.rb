# frozen_string_literal: true

require "digest"

module Identity
  module Services
    class ResetPassword < Shared::Services::BaseService
      MIN_PASSWORD_LENGTH = 8

      Error = Identity::Errors::Error
      InvalidToken = Identity::Errors::InvalidToken
      TokenExpired = Identity::Errors::TokenExpired
      TokenAlreadyUsed = Identity::Errors::TokenAlreadyUsed
      UserNotFound = Identity::Errors::UserNotFound
      WeakPassword = Identity::Errors::WeakPassword
      MissingDependency = Identity::Errors::MissingDependency

      Result = Struct.new(:user, :events, keyword_init: true) do
        def success?
          true
        end
      end

      def initialize(
        user_id:,
        raw_token:,
        new_password:,
        user_repository:,
        token_store:,
        password_hasher: BCryptPasswordHasher.new,
        event_publisher: NullEventPublisher.new,
        clock: -> { Time.current }
      )
        @user_id = user_id
        @raw_token = raw_token
        @new_password = new_password
        @user_repository = user_repository
        @token_store = token_store
        @password_hasher = password_hasher
        @event_publisher = event_publisher
        @clock = clock
      end

      def call
        now = @clock.call
        user = find_user!
        token_digest = Digest::SHA256.hexdigest(@raw_token.to_s)
        password_reset_token = find_token!(token_digest)

        validate_token!(password_reset_token, now)
        validate_password!(@new_password)

        user.password_digest = @password_hasher.digest(@new_password)
        user.updated_at = now

        event = Identity::Events::PasswordResetCompleted.new(
          {
            user_id: user.id,
            reset_at: now
          },
          occurred_at: now
        )

        @user_repository.save(user)
        @token_store.mark_token_used(user_id: @user_id, token_digest: token_digest, used_at: now)
        @event_publisher.publish(event)

        Result.new(user: user, events: [ event ])
      end

      private

      def find_user!
        unless @user_repository.respond_to?(:find_by_id)
          raise MissingDependency, "user_repository must respond to find_by_id"
        end

        user = @user_repository.find_by_id(@user_id)
        raise UserNotFound, "user not found" if user.nil?

        user
      end

      def find_token!(token_digest)
        unless @token_store.respond_to?(:find_token)
          raise MissingDependency, "token_store must respond to find_token"
        end

        token = @token_store.find_token(user_id: @user_id, token_digest: token_digest)
        raise InvalidToken, "password reset token is invalid" if token.nil?

        token
      end

      def validate_token!(password_reset_token, now)
        raise TokenAlreadyUsed, "password reset token was already used" if password_reset_token.used?
        raise TokenExpired, "password reset token has expired" if password_reset_token.expired?(now: now)
      end

      def validate_password!(password)
        password = password.to_s

        return if password.length >= MIN_PASSWORD_LENGTH &&
                  password.match?(/[[:alpha:]]/) &&
                  password.match?(/[[:digit:]]/)

        raise WeakPassword, "password must have at least 8 characters, including letters and numbers"
      end

      class BCryptPasswordHasher
        def digest(password)
          require "bcrypt"

          BCrypt::Password.create(password).to_s
        rescue LoadError
          raise MissingDependency, "bcrypt is required to hash passwords"
        end
      end

      class NullEventPublisher
        def publish(event)
          true
        end
      end
    end
  end
end
