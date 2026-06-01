# frozen_string_literal: true

module Identity
  module Services
    class ApproveSeller < Shared::Services::BaseService
      include Identity::Services::ServiceHelpers

      Error = Identity::Errors::Error
      SellerProfileNotFound = Identity::Errors::SellerProfileNotFound
      UserNotFound = Identity::Errors::UserNotFound
      ReviewerNotFound = Identity::Errors::ReviewerNotFound
      PermissionDenied = Identity::Errors::PermissionDenied
      InvalidSellerProfileState = Identity::Errors::InvalidSellerProfileState
      MissingDependency = Identity::Errors::MissingDependency

      Result = Struct.new(:seller_profile, :user, :events, keyword_init: true) do
        def success?
          true
        end
      end

      def initialize(
        seller_profile_id:,
        reviewed_by_user_id:,
        user_repository:,
        seller_profile_repository:,
        event_publisher: NullEventPublisher.new,
        clock: -> { Time.current }
      )
        @seller_profile_id = seller_profile_id
        @reviewed_by_user_id = reviewed_by_user_id
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
        validate_pending_review!(seller_profile)

        seller_profile.approve!(reviewed_by_user_id: @reviewed_by_user_id, reviewed_at: now)
        user.grant_role(
          Identity::Entities::Role::SELLER,
          granted_by_user_id: @reviewed_by_user_id,
          reason: "approved seller application #{@seller_profile_id}",
          granted_at: now
        )

        event = Identity::Events::SellerApproved.new(
          {
            user_id: user.id,
            seller_profile_id: seller_profile.id,
            reviewed_by_user_id: @reviewed_by_user_id,
            approved_at: now
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
        find_user_by_id!(@reviewed_by_user_id, not_found_error: ReviewerNotFound, not_found_message: "reviewer not found")
      end

      def find_user!(user_id)
        find_user_by_id!(user_id, not_found_error: UserNotFound, not_found_message: "user not found")
      end

      def validate_reviewer!(reviewer)
        authorize_platform_admin!(reviewer)
      end

      def validate_pending_review!(seller_profile)
        return if seller_profile.pending_review?

        raise InvalidSellerProfileState, "seller profile must be pending_review"
      end

      class NullEventPublisher
        def publish(event)
          true
        end
      end
    end
  end
end
