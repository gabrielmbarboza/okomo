# frozen_string_literal: true

module Identity
  module Services
    module ServiceHelpers
      private

      def ensure_repository_method!(repository, method_name, dependency_name)
        return if repository.respond_to?(method_name)

        raise self.class::MissingDependency, "#{dependency_name} must respond to #{method_name}"
      end

      def find_record!(repository:, id:, dependency_name:, not_found_error:, not_found_message:)
        ensure_repository_method!(repository, :find_by_id, dependency_name)

        record = repository.find_by_id(id)
        raise not_found_error, not_found_message if record.nil?

        record
      end

      def find_user_by_id!(user_id, not_found_error:, not_found_message:)
        find_record!(
          repository: @user_repository,
          id: user_id,
          dependency_name: "user_repository",
          not_found_error: not_found_error,
          not_found_message: not_found_message
        )
      end

      def find_seller_profile_by_id!(seller_profile_id)
        find_record!(
          repository: @seller_profile_repository,
          id: seller_profile_id,
          dependency_name: "seller_profile_repository",
          not_found_error: self.class::SellerProfileNotFound,
          not_found_message: "seller profile not found"
        )
      end

      def authorize_platform_admin!(user, error_class: self.class::PermissionDenied)
        Identity::Services::AuthorizeUser.call(
          user: user,
          required_roles: [ Identity::Entities::Role::PLATFORM_ADMIN ]
        )
      rescue Identity::Services::AuthorizeUser::Error
        raise error_class, "reviewer must have platform_admin role"
      end
    end
  end
end
