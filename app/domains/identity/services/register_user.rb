# frozen_string_literal: true

require "digest"
require "securerandom"
require "uri"

module Identity
  module Services
    class RegisterUser < Shared::Services::BaseService
      CONFIRMATION_TOKEN_TTL = 24.hours
      MIN_PASSWORD_LENGTH = 8

      Error = Identity::Errors::Error
      InvalidEmail = Identity::Errors::InvalidEmail
      EmailAlreadyRegistered = Identity::Errors::EmailAlreadyRegistered
      WeakPassword = Identity::Errors::WeakPassword
      MissingDependency = Identity::Errors::MissingDependency

      Result = Struct.new(:user, :confirmation_token, :events, keyword_init: true) do
        def success?
          true
        end
      end

      def initialize(
        email:,
        password:,
        name: nil,
        user_repository:,
        password_hasher: BCryptPasswordHasher.new,
        confirmation_token_generator: SecureConfirmationTokenGenerator.new,
        confirmation_delivery: NullConfirmationDelivery.new,
        event_publisher: NullEventPublisher.new,
        clock: -> { Time.current }
      )
        @email = email
        @password = password
        @name = name
        @user_repository = user_repository
        @password_hasher = password_hasher
        @confirmation_token_generator = confirmation_token_generator
        @confirmation_delivery = confirmation_delivery
        @event_publisher = event_publisher
        @clock = clock
      end

      def call
        now = @clock.call
        normalized_email = normalize_email(@email)

        validate_email!(normalized_email)
        validate_unique_email!(normalized_email)
        validate_password!(@password)

        user = Identity::Entities::User.new(
          name: @name,
          email: normalized_email,
          password_digest: @password_hasher.digest(@password),
          status: Identity::Entities::User::PENDING_CONFIRMATION,
          email_confirmed_at: nil,
          created_at: now,
          updated_at: now
        )
        confirmation_token = @confirmation_token_generator.generate(
          user: user,
          expires_at: now + CONFIRMATION_TOKEN_TTL
        )
        event = Identity::Events::UserRegistered.new(
          {
            user_id: user.id,
            created_at: user.created_at
          },
          occurred_at: now
        )

        @user_repository.save(user)
        @confirmation_delivery.deliver(user: user, confirmation_token: confirmation_token)
        @event_publisher.publish(event)

        Result.new(user: user, confirmation_token: confirmation_token, events: [ event ])
      end

      private

      def normalize_email(email)
        email.to_s.strip.downcase
      end

      def validate_email!(email)
        raise InvalidEmail, "email is invalid" unless email.match?(URI::MailTo::EMAIL_REGEXP)
      end

      def validate_unique_email!(email)
        return unless email_registered?(email)

        raise EmailAlreadyRegistered, "email already registered"
      end

      def validate_password!(password)
        password = password.to_s

        return if password.length >= MIN_PASSWORD_LENGTH &&
                  password.match?(/[[:alpha:]]/) &&
                  password.match?(/[[:digit:]]/)

        raise WeakPassword, "password must have at least 8 characters, including letters and numbers"
      end

      def email_registered?(email)
        if @user_repository.respond_to?(:email_exists?)
          @user_repository.email_exists?(email)
        elsif @user_repository.respond_to?(:exists?)
          @user_repository.exists?(email: email)
        elsif @user_repository.respond_to?(:find_by_email)
          !@user_repository.find_by_email(email).nil?
        else
          raise MissingDependency, "user_repository must respond to email_exists?, exists?, or find_by_email"
        end
      end

      class BCryptPasswordHasher
        def digest(password)
          require "bcrypt"

          BCrypt::Password.create(password).to_s
        rescue LoadError
          raise MissingDependency, "bcrypt is required to hash passwords"
        end
      end

      class SecureConfirmationTokenGenerator
        def generate(user:, expires_at:)
          raw_token = SecureRandom.urlsafe_base64(32)

          Identity::ValueObjects::ConfirmationToken.new(
            raw_token: raw_token,
            token_digest: Digest::SHA256.hexdigest(raw_token),
            expires_at: expires_at
          )
        end
      end

      class NullConfirmationDelivery
        def deliver(user:, confirmation_token:)
          true
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
