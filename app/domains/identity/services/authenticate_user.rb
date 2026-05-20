# frozen_string_literal: true

module Identity
  module Services
    class AuthenticateUser < Shared::Services::BaseService
      ACCESS_TOKEN_TTL = 15.minutes

      class Error < StandardError; end
      class InvalidCredentials < Error; end
      class EmailNotConfirmed < Error; end
      class UserBlocked < Error; end
      class UserDeactivated < Error; end
      class MissingDependency < Error; end

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
        access_token_generator: JwtAccessTokenGenerator.new,
        event_publisher: NullEventPublisher.new,
        clock: -> { Time.current }
      )
        @email = email
        @password = password
        @user_repository = user_repository
        @password_verifier = password_verifier
        @access_token_generator = access_token_generator
        @event_publisher = event_publisher
        @clock = clock
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
        def initialize(secret: nil)
          @secret = secret
        end

        def generate(user:, roles:, expires_at:)
          require "jwt"

          JWT.encode(
            {
              sub: user.id,
              roles: roles,
              exp: expires_at.to_i
            },
            secret,
            "HS256"
          )
        rescue LoadError
          raise MissingDependency, "jwt is required to generate access tokens"
        end

        private

        def secret
          @secret || Rails.application.secret_key_base
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
