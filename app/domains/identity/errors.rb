# frozen_string_literal: true

module Identity
  module Errors
    class Error < StandardError; end

    class MissingDependency < Error; end

    class UserNotFound < Error; end
    class ReviewerNotFound < Error; end
    class SellerProfileNotFound < Error; end

    class PermissionDenied < Error; end
    class AccessDenied < Error; end

    class InvalidCredentials < Error; end
    class EmailNotConfirmed < Error; end
    class UserBlocked < Error; end
    class UserDeactivated < Error; end
    class UserRequired < Error; end
    class UserAlreadyConfirmed < Error; end
    class UserNotAllowed < Error; end

    class InvalidToken < Error; end
    class TokenExpired < Error; end
    class ExpiredToken < Error; end
    class TokenAlreadyUsed < Error; end
    class InvalidClaims < Error; end

    class InvalidEmail < Error; end
    class EmailAlreadyRegistered < Error; end
    class WeakPassword < Error; end

    class InvalidRole < Error; end
    class InvalidReason < Error; end
    class InvalidDocument < Error; end
    class InvalidSellerApplication < Error; end
    class InvalidSellerProfileState < Error; end
    class SellerProfileAlreadyExists < Error; end
    class SellerRoleNotActive < Error; end
    class SellerRoleAlreadyActive < Error; end
  end
end
