# frozen_string_literal: true

module Identity
  module Services
    class AuthorizeUser < Shared::Services::BaseService
      Error = Identity::Errors::Error
      UserRequired = Identity::Errors::UserRequired
      InvalidRole = Identity::Errors::InvalidRole
      AccessDenied = Identity::Errors::AccessDenied

      Result = Struct.new(:user, :required_roles, :effective_roles, :matched_roles, keyword_init: true) do
        def success?
          true
        end
      end

      def initialize(user:, required_roles:, require_all: false)
        @user = user
        @required_roles = Array(required_roles)
        @require_all = require_all
      end

      def call
        validate_user!
        validate_required_roles!

        effective_roles = @user.effective_roles
        raise AccessDenied, "user has no effective roles" if effective_roles.empty?

        matched_roles = effective_roles & @required_roles
        validate_authorization!(matched_roles)

        Result.new(
          user: @user,
          required_roles: @required_roles,
          effective_roles: effective_roles,
          matched_roles: matched_roles
        )
      end

      private

      def validate_user!
        raise UserRequired, "user is required" if @user.nil?
        return if @user.respond_to?(:effective_roles)

        raise UserRequired, "user must respond to effective_roles"
      end

      def validate_required_roles!
        raise InvalidRole, "required_roles cannot be empty" if @required_roles.empty?

        invalid_roles = @required_roles - Identity::Entities::Role::VALID_NAMES
        return if invalid_roles.empty?

        raise InvalidRole,
              "required_roles must contain only: #{Identity::Entities::Role::VALID_NAMES.join(', ')}"
      end

      def validate_authorization!(matched_roles)
        return if @require_all ? matched_roles.size == @required_roles.size : matched_roles.any?

        message = @require_all ? "user does not have all required roles" : "user does not have required role"
        raise AccessDenied, message
      end
    end
  end
end
