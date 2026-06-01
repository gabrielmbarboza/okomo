# frozen_string_literal: true

module Identity
  module Services
    class RejectSeller < Shared::Services::BaseService
      include Identity::Services::ServiceHelpers

      Error = Identity::Errors::Error
      SellerProfileNotFound = Identity::Errors::SellerProfileNotFound
      ReviewerNotFound = Identity::Errors::ReviewerNotFound
      PermissionDenied = Identity::Errors::PermissionDenied
      InvalidSellerProfileState = Identity::Errors::InvalidSellerProfileState
      InvalidReason = Identity::Errors::InvalidReason
      MissingDependency = Identity::Errors::MissingDependency

      Result = Struct.new(:seller_profile, :events, keyword_init: true) do
        def success?
          true
        end
      end

      def initialize(
        seller_profile_id:,
        reviewed_by_user_id:,
        reason:,
        user_repository:,
        seller_profile_repository:,
        event_publisher: NullEventPublisher.new,
        clock: -> { Time.current }
      )
        @seller_profile_id = seller_profile_id
        @reviewed_by_user_id = reviewed_by_user_id
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

        validate_reviewer!(reviewer)
        validate_pending_review!(seller_profile)
        validate_reason!

        seller_profile.reject!(
          reviewed_by_user_id: @reviewed_by_user_id,
          reason: @reason,
          reviewed_at: now
        )

        event = Identity::Events::SellerRejected.new(
          {
            user_id: seller_profile.user_id,
            seller_profile_id: seller_profile.id,
            reviewed_by_user_id: @reviewed_by_user_id,
            rejection_reason: @reason,
            rejected_at: now
          },
          occurred_at: now
        )

        @seller_profile_repository.save(seller_profile)
        @event_publisher.publish(event)

        Result.new(seller_profile: seller_profile, events: [ event ])
      end

      private

      def find_seller_profile!
        find_seller_profile_by_id!(@seller_profile_id)
      end

      def find_reviewer!
        find_user_by_id!(@reviewed_by_user_id, not_found_error: ReviewerNotFound, not_found_message: "reviewer not found")
      end

      def validate_reviewer!(reviewer)
        authorize_platform_admin!(reviewer)
      end

      def validate_pending_review!(seller_profile)
        return if seller_profile.pending_review?

        raise InvalidSellerProfileState, "seller profile must be pending_review"
      end

      def validate_reason!
        return unless @reason.blank?

        raise InvalidReason, "rejection_reason cannot be nil or empty"
      end

      class NullEventPublisher
        def publish(event)
          true
        end
      end
    end
  end
end
