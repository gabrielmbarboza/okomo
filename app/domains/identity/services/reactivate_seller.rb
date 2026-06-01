# frozen_string_literal: true

module Identity
  module Services
    class ReactivateSeller < Shared::Services::BaseService
      include Identity::Services::ServiceHelpers

      Error = Identity::Errors::Error
      SellerProfileNotFound = Identity::Errors::SellerProfileNotFound
      UserNotFound = Identity::Errors::UserNotFound
      ReviewerNotFound = Identity::Errors::ReviewerNotFound
      PermissionDenied = Identity::Errors::PermissionDenied
      InvalidSellerProfileState = Identity::Errors::InvalidSellerProfileState
      SellerRoleAlreadyActive = Identity::Errors::SellerRoleAlreadyActive
      InvalidReason = Identity::Errors::InvalidReason
      MissingDependency = Identity::Errors::MissingDependency

      Result = Struct.new(:seller_profile, :user, :events, keyword_init: true) do
        def success?
          true
        end
      end

      def initialize(
        seller_profile_id:,
        reactivated_by_user_id:,
        reason:,
        user_repository:,
        seller_profile_repository:,
        event_publisher: NullEventPublisher.new,
        clock: -> { Time.current }
      )
        @seller_profile_id = seller_profile_id
        @reactivated_by_user_id = reactivated_by_user_id
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
        validate_suspended!(seller_profile)
        validate_reason!
        validate_seller_role_inactive!(user)

        seller_profile.reactivate!(reactivated_at: now)
        user.grant_role(
          Identity::Entities::Role::SELLER,
          granted_by_user_id: @reactivated_by_user_id,
          reason: @reason,
          granted_at: now
        )

        event = Identity::Events::SellerReactivated.new(
          {
            user_id: user.id,
            seller_profile_id: seller_profile.id,
            reactivated_by_user_id: @reactivated_by_user_id,
            reactivated_at: now
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
        find_user_by_id!(@reactivated_by_user_id, not_found_error: ReviewerNotFound, not_found_message: "reviewer not found")
      end

      def find_user!(user_id)
        find_user_by_id!(user_id, not_found_error: UserNotFound, not_found_message: "user not found")
      end

      def validate_reviewer!(reviewer)
        authorize_platform_admin!(reviewer)
      end

      def validate_suspended!(seller_profile)
        return if seller_profile.suspended?

        raise InvalidSellerProfileState, "seller profile must be suspended"
      end

      def validate_reason!
        return unless @reason.blank?

        raise InvalidReason, "reactivation_reason cannot be nil or empty"
      end

      def validate_seller_role_inactive!(user)
        return unless user.has_role?(Identity::Entities::Role::SELLER)

        raise SellerRoleAlreadyActive, "seller role is already active"
      end

      class NullEventPublisher
        def publish(event)
          true
        end
      end
    end
  end
end
