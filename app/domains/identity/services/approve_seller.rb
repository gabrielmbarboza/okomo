# frozen_string_literal: true

module Identity
  module Services
    class ApproveSeller < Shared::Services::BaseService
      class Error < StandardError; end
      class SellerProfileNotFound < Error; end
      class UserNotFound < Error; end
      class ReviewerNotFound < Error; end
      class PermissionDenied < Error; end
      class InvalidSellerProfileState < Error; end
      class MissingDependency < Error; end

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
        ensure_repository_method!(@seller_profile_repository, :find_by_id, "seller_profile_repository")

        seller_profile = @seller_profile_repository.find_by_id(@seller_profile_id)
        raise SellerProfileNotFound, "seller profile not found" if seller_profile.nil?

        seller_profile
      end

      def find_reviewer!
        reviewer = find_user_record(@reviewed_by_user_id)
        raise ReviewerNotFound, "reviewer not found" if reviewer.nil?

        reviewer
      end

      def find_user!(user_id)
        user = find_user_record(user_id)
        raise UserNotFound, "user not found" if user.nil?

        user
      end

      def find_user_record(user_id)
        ensure_repository_method!(@user_repository, :find_by_id, "user_repository")

        @user_repository.find_by_id(user_id)
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
