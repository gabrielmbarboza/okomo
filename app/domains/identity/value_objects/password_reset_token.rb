# frozen_string_literal: true

module Identity
  module ValueObjects
    class PasswordResetToken < Shared::ValueObjects::BaseValueObject
      attr_reader :raw_token, :token_digest, :expires_at, :used_at

      def initialize(raw_token:, token_digest:, expires_at:, used_at: nil)
        raise ArgumentError, "raw_token cannot be nil or empty" if raw_token.blank?
        raise ArgumentError, "token_digest cannot be nil or empty" if token_digest.blank?
        raise ArgumentError, "expires_at cannot be nil" if expires_at.nil?

        super
      end

      def expired?(now: Time.current)
        expires_at <= now
      end

      def used?
        used_at.present?
      end

      def usable?(now: Time.current)
        !expired?(now: now) && !used?
      end
    end
  end
end
