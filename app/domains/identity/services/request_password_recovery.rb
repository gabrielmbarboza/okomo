# frozen_string_literal: true

require "digest"
require "securerandom"

module Identity
  module Services
    class RequestPasswordRecovery < Shared::Services::BaseService
      PASSWORD_RESET_TOKEN_TTL = 2.hours

      class Error < StandardError; end
      class MissingDependency < Error; end

      Result = Struct.new(:user, :password_reset_token, :events, keyword_init: true) do
        def success?
          true
        end
      end

      def initialize(
        email:,
        user_repository:,
        token_store:,
        password_reset_token_generator: SecurePasswordResetTokenGenerator.new,
        recovery_delivery: NullRecoveryDelivery.new,
        event_publisher: NullEventPublisher.new,
        clock: -> { Time.current }
      )
        @email = email
        @user_repository = user_repository
        @token_store = token_store
        @password_reset_token_generator = password_reset_token_generator
        @recovery_delivery = recovery_delivery
        @event_publisher = event_publisher
        @clock = clock
      end

      def call
        now = @clock.call
        user = find_user(normalize_email(@email))
        return Result.new(user: nil, password_reset_token: nil, events: []) if user.nil?

        password_reset_token = @password_reset_token_generator.generate(
          user: user,
          expires_at: now + PASSWORD_RESET_TOKEN_TTL
        )
        event = Identity::Events::PasswordRecoveryRequested.new(
          {
            user_id: user.id,
            requested_at: now
          },
          occurred_at: now
        )

        @token_store.store_token(user.id, password_reset_token)
        @recovery_delivery.deliver(user: user, password_reset_token: password_reset_token)
        @event_publisher.publish(event)

        Result.new(user: user, password_reset_token: password_reset_token, events: [ event ])
      end

      private

      def normalize_email(email)
        email.to_s.strip.downcase
      end

      def find_user(email)
        unless @user_repository.respond_to?(:find_by_email)
          raise MissingDependency, "user_repository must respond to find_by_email"
        end

        @user_repository.find_by_email(email)
      end

      class SecurePasswordResetTokenGenerator
        def generate(user:, expires_at:)
          raw_token = SecureRandom.urlsafe_base64(32)

          Identity::ValueObjects::PasswordResetToken.new(
            raw_token: raw_token,
            token_digest: Digest::SHA256.hexdigest(raw_token),
            expires_at: expires_at
          )
        end
      end

      class NullRecoveryDelivery
        def deliver(user:, password_reset_token:)
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
