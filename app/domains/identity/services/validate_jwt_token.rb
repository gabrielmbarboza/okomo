# frozen_string_literal: true

module Identity
  module Services
    class ValidateJwtToken < Shared::Services::BaseService
      REQUIRED_CLAIMS = %w[sub roles exp iat jti].freeze

      Error = Identity::Errors::Error
      InvalidToken = Identity::Errors::InvalidToken
      ExpiredToken = Identity::Errors::ExpiredToken
      InvalidClaims = Identity::Errors::InvalidClaims
      MissingDependency = Identity::Errors::MissingDependency

      Result = Struct.new(:user_id, :roles, :expires_at, :issued_at, :token_id, :payload, keyword_init: true) do
        def success?
          true
        end
      end

      def initialize(
        token:,
        secret: nil,
        clock: -> { Time.current }
      )
        @token = token
        @secret = secret
        @clock = clock
      end

      def call
        require "jwt"

        payload = decode_payload
        validate_required_claims!(payload)
        validate_expiration!(payload)

        Result.new(
          user_id: payload.fetch("sub"),
          roles: payload.fetch("roles"),
          expires_at: Time.zone.at(payload.fetch("exp")),
          issued_at: Time.zone.at(payload.fetch("iat")),
          token_id: payload.fetch("jti"),
          payload: payload
        )
      rescue JWT::DecodeError
        raise InvalidToken, "token is invalid"
      rescue LoadError
        raise MissingDependency, "jwt is required to validate access tokens"
      end

      private

      def decode_payload
        payload, = JWT.decode(
          @token,
          secret,
          true,
          {
            algorithm: GenerateJwtToken::ALGORITHM,
            iss: GenerateJwtToken::ISSUER,
            verify_iss: true,
            aud: GenerateJwtToken::AUDIENCE,
            verify_aud: true,
            verify_expiration: false
          }
        )
        payload
      end

      def validate_required_claims!(payload)
        return if REQUIRED_CLAIMS.all? { |claim| payload[claim].present? } && payload["roles"].is_a?(Array)

        raise InvalidClaims, "token payload is missing required claims"
      end

      def validate_expiration!(payload)
        return if Time.zone.at(payload.fetch("exp")) > @clock.call

        raise ExpiredToken, "token has expired"
      end

      def secret
        @secret || Rails.application.secret_key_base
      end
    end
  end
end
