# frozen_string_literal: true

require "securerandom"

module Identity
  module Services
    class GenerateJwtToken < Shared::Services::BaseService
      ACCESS_TOKEN_TTL = 15.minutes
      ALGORITHM = "HS256"
      ISSUER = "okomo"
      AUDIENCE = "okomo-api"

      class Error < StandardError; end
      class MissingDependency < Error; end

      Result = Struct.new(:access_token, :expires_at, :issued_at, :payload, keyword_init: true) do
        def success?
          true
        end
      end

      def initialize(
        user:,
        roles:,
        expires_at: nil,
        secret: nil,
        clock: -> { Time.current }
      )
        @user = user
        @roles = roles
        @expires_at = expires_at
        @secret = secret
        @clock = clock
      end

      def call
        require "jwt"

        issued_at = @clock.call
        expires_at = @expires_at || issued_at + ACCESS_TOKEN_TTL
        payload = build_payload(issued_at: issued_at, expires_at: expires_at)
        access_token = JWT.encode(payload, secret, ALGORITHM)

        Result.new(
          access_token: access_token,
          expires_at: expires_at,
          issued_at: issued_at,
          payload: payload
        )
      rescue LoadError
        raise MissingDependency, "jwt is required to generate access tokens"
      end

      private

      def build_payload(issued_at:, expires_at:)
        {
          sub: @user.id,
          roles: @roles,
          iat: issued_at.to_i,
          exp: expires_at.to_i,
          iss: ISSUER,
          aud: AUDIENCE,
          jti: SecureRandom.uuid
        }
      end

      def secret
        @secret || Rails.application.secret_key_base
      end
    end
  end
end
