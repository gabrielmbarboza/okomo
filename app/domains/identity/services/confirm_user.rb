# frozen_string_literal: true

require "digest"

module Identity
  module Services
    class ConfirmUser < Shared::Services::BaseService
      class Error < StandardError; end
      class InvalidToken < Error; end
      class TokenExpired < Error; end
      class UserNotFound < Error; end
      class UserAlreadyConfirmed < Error; end
      class MissingDependency < Error; end

      Result = Struct.new(:user, :events, keyword_init: true) do
        def success?
          true
        end
      end

      def initialize(
        user_id:,
        raw_token:,
        user_repository:,
        token_store:,
        event_publisher: NullEventPublisher.new,
        clock: -> { Time.current }
      )
        @user_id = user_id
        @raw_token = raw_token
        @user_repository = user_repository
        @token_store = token_store
        @event_publisher = event_publisher
        @clock = clock
      end

      def call
        now = @clock.call

        user = find_user!
        check_user_already_confirmed!(user)
        validate_token!(now)

        user.confirm_email!(confirmed_at: now)

        event = Identity::Events::UserEmailConfirmed.new(
          {
            user_id: user.id
          },
          occurred_at: now
        )

        @user_repository.save(user)
        @token_store.delete_token(@user_id)
        @event_publisher.publish(event)

        Result.new(user: user, events: [ event ])
      end

      private

      def validate_token!(now)
        stored_token = @token_store.get_token(@user_id)
        raise InvalidToken, "confirmation token is invalid" if stored_token.nil?

        token_digest = Digest::SHA256.hexdigest(@raw_token)
        raise InvalidToken, "confirmation token is invalid" if stored_token.token_digest != token_digest

        raise TokenExpired, "confirmation token has expired" if stored_token.expired?(now: now)
      end

      def find_user!
        user = @user_repository.find_by_id(@user_id)
        raise UserNotFound, "user not found" if user.nil?

        user
      end

      def check_user_already_confirmed!(user)
        raise UserAlreadyConfirmed, "user email already confirmed" if user.email_confirmed?
      end
    end
  end
end
