# frozen_string_literal: true

module Identity
  module Services
    class RejectSeller < Shared::Services::BaseService
      class Error < StandardError; end
      class SellerProfileNotFound < Error; end
      class ReviewerNotFound < Error; end
      class PermissionDenied < Error; end
      class InvalidSellerProfileState < Error; end
      class InvalidReason < Error; end
      class MissingDependency < Error; end

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
        ensure_repository_method!(@seller_profile_repository, :find_by_id, "seller_profile_repository")

        seller_profile = @seller_profile_repository.find_by_id(@seller_profile_id)
        raise SellerProfileNotFound, "seller profile not found" if seller_profile.nil?

        seller_profile
      end

      def find_reviewer!
        ensure_repository_method!(@user_repository, :find_by_id, "user_repository")

        reviewer = @user_repository.find_by_id(@reviewed_by_user_id)
        raise ReviewerNotFound, "reviewer not found" if reviewer.nil?

        reviewer
      end

      def validate_reviewer!(reviewer)
        Identity::Services::AuthorizeUser.call(
          user: reviewer,
          required_roles: [ Identity::Entities::Role::PLATFORM_ADMIN ]
        )
      rescue Identity::Services::AuthorizeUser::Error

        raise PermissionDenied, "reviewer must have platform_admin role"
      end

      def validate_pending_review!(seller_profile)
        return if seller_profile.pending_review?

        raise InvalidSellerProfileState, "seller profile must be pending_review"
      end

      def validate_reason!
        return unless @reason.blank?

        raise InvalidReason, "rejection_reason cannot be nil or empty"
      end

      def ensure_repository_method!(repository, method_name, dependency_name)
        return if repository.respond_to?(method_name)

        raise MissingDependency, "#{dependency_name} must respond to #{method_name}"
      end

      class NullEventPublisher
        def publish(event)
          true
        end
      end
    end
  end
end
