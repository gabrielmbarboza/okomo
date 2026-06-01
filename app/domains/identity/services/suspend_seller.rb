# frozen_string_literal: true

module Identity
  module Services
    class SuspendSeller < Shared::Services::BaseService
      include Identity::Services::ServiceHelpers

      Error = Identity::Errors::Error
      SellerProfileNotFound = Identity::Errors::SellerProfileNotFound
      UserNotFound = Identity::Errors::UserNotFound
      ReviewerNotFound = Identity::Errors::ReviewerNotFound
      PermissionDenied = Identity::Errors::PermissionDenied
      InvalidSellerProfileState = Identity::Errors::InvalidSellerProfileState
      SellerRoleNotActive = Identity::Errors::SellerRoleNotActive
      InvalidReason = Identity::Errors::InvalidReason
      MissingDependency = Identity::Errors::MissingDependency

      Result = Struct.new(:seller_profile, :user, :events, keyword_init: true) do
        def success?
          true
        end
      end

      def initialize(
        seller_profile_id:,
        suspended_by_user_id:,
        reason:,
        user_repository:,
        seller_profile_repository:,
        event_publisher: NullEventPublisher.new,
        clock: -> { Time.current }
      )
        @seller_profile_id = seller_profile_id
        @suspended_by_user_id = suspended_by_user_id
        @reason = reason
        @user_repository = user_repository
        @seller_profile_repository = seller_profile_repository
        @event_publisher = event_publisher
        @clock = clock
      end

      def call
        now = @clock.call
        seller_profile = find_seller_profile!
        reviewer = find_reviewer!
        user = find_user!(seller_profile.user_id)

        validate_reviewer!(reviewer)
        validate_approved!(seller_profile)
        validate_reason!
        validate_seller_role!(user)

        seller_profile.suspend!(reason: @reason, suspended_at: now)
        user.revoke_role(
          Identity::Entities::Role::SELLER,
          revoked_by_user_id: @suspended_by_user_id,
          reason: @reason,
          revoked_at: now
        )

        event = Identity::Events::SellerSuspended.new(
          {
            user_id: user.id,
            seller_profile_id: seller_profile.id,
            suspension_reason: @reason,
            suspended_at: now
          },
          occurred_at: now
        )

        @seller_profile_repository.save(seller_profile)
        @user_repository.save(user)
        @event_publisher.publish(event)

        Result.new(seller_profile: seller_profile, user: user, events: [ event ])
      end

      private

      def find_seller_profile!
        find_seller_profile_by_id!(@seller_profile_id)
      end

      def find_reviewer!
        find_user_by_id!(@suspended_by_user_id, not_found_error: ReviewerNotFound, not_found_message: "reviewer not found")
      end

      def find_user!(user_id)
        find_user_by_id!(user_id, not_found_error: UserNotFound, not_found_message: "user not found")
      end

      def validate_reviewer!(reviewer)
        authorize_platform_admin!(reviewer)
      end

      def validate_approved!(seller_profile)
        return if seller_profile.approved?

        raise InvalidSellerProfileState, "seller profile must be approved"
      end

      def validate_reason!
        return unless @reason.blank?

        raise InvalidReason, "suspension_reason cannot be nil or empty"
      end

      def validate_seller_role!(user)
        return if user.has_role?(Identity::Entities::Role::SELLER)

        raise SellerRoleNotActive, "seller role is not active"
      end

      class NullEventPublisher
        def publish(event)
          true
        end
      end
    end
  end
end
