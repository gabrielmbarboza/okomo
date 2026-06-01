# frozen_string_literal: true

module Identity
  module Services
    class AuthenticateUser < Shared::Services::BaseService
      ACCESS_TOKEN_TTL = 15.minutes

      Error = Identity::Errors::Error
      InvalidCredentials = Identity::Errors::InvalidCredentials
      EmailNotConfirmed = Identity::Errors::EmailNotConfirmed
      UserBlocked = Identity::Errors::UserBlocked
      UserDeactivated = Identity::Errors::UserDeactivated
      MissingDependency = Identity::Errors::MissingDependency

      Result = Struct.new(:user, :access_token, :expires_at, :roles, :events, keyword_init: true) do
        def success?
          true
        end
      end

      def initialize(
        email:,
        password:,
        user_repository:,
        password_verifier: BCryptPasswordVerifier.new,
        access_token_generator: nil,
        event_publisher: NullEventPublisher.new,
        clock: -> { Time.current }
      )
        @email = email
        @password = password
        @user_repository = user_repository
        @password_verifier = password_verifier
        @event_publisher = event_publisher
        @clock = clock
        @access_token_generator = access_token_generator || JwtAccessTokenGenerator.new(clock: @clock)
      end

      def call
        now = @clock.call
        user = find_user!(normalize_email(@email))

        validate_password!(user)
        validate_login_allowed!(user)

        roles = user.active_roles
        expires_at = now + ACCESS_TOKEN_TTL
        access_token = @access_token_generator.generate(user: user, roles: roles, expires_at: expires_at)

        user.record_login!(logged_in_at: now)

        event = Identity::Events::UserAuthenticated.new(
          {
            user_id: user.id,
            roles: roles,
            authenticated_at: now
          },
          occurred_at: now
        )

        @user_repository.save(user)
        @event_publisher.publish(event)

        Result.new(
          user: user,
          access_token: access_token,
          expires_at: expires_at,
          roles: roles,
          events: [ event ]
        )
      end

      private

      def normalize_email(email)
        email.to_s.strip.downcase
      end

      def find_user!(email)
        unless @user_repository.respond_to?(:find_by_email)
          raise MissingDependency, "user_repository must respond to find_by_email"
        end

        user = @user_repository.find_by_email(email)
        raise InvalidCredentials, "invalid credentials" if user.nil?

        user
      end

      def validate_password!(user)
        matches = @password_verifier.matches?(
          password_digest: user.password_digest,
          password: @password
        )
        raise InvalidCredentials, "invalid credentials" unless matches
      end

      def validate_login_allowed!(user)
        raise EmailNotConfirmed, "email must be confirmed before login" unless user.email_confirmed?
        raise UserBlocked, "user is blocked" if user.blocked?
        raise UserDeactivated, "user is deactivated" if user.deactivated?
        raise InvalidCredentials, "invalid credentials" unless user.can_login?
      end

      class BCryptPasswordVerifier
        def matches?(password_digest:, password:)
          require "bcrypt"

          BCrypt::Password.new(password_digest) == password.to_s
        rescue BCrypt::Errors::InvalidHash, LoadError
          false
        end
      end

      class JwtAccessTokenGenerator
        def initialize(secret: nil, clock: -> { Time.current })
          @secret = secret
          @clock = clock
        end

        def generate(user:, roles:, expires_at:)
          Identity::Services::GenerateJwtToken.call(
            user: user,
            roles: roles,
            expires_at: expires_at,
            secret: @secret,
            clock: @clock
          ).access_token
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
