# frozen_string_literal: true

require "uri"

module Identity
  module Services
    class RequestSellerApplication < Shared::Services::BaseService
      include Identity::Services::ServiceHelpers

      REQUIRED_ADDRESS_FIELDS = %w[street number city state zip_code].freeze

      Error = Identity::Errors::Error
      UserNotFound = Identity::Errors::UserNotFound
      UserNotAllowed = Identity::Errors::UserNotAllowed
      SellerProfileAlreadyExists = Identity::Errors::SellerProfileAlreadyExists
      InvalidDocument = Identity::Errors::InvalidDocument
      InvalidSellerApplication = Identity::Errors::InvalidSellerApplication
      MissingDependency = Identity::Errors::MissingDependency

      Result = Struct.new(:seller_profile, :events, keyword_init: true) do
        def success?
          true
        end
      end

      def initialize(
        user_id:,
        display_name:,
        description: nil,
        document_type:,
        document_number:,
        legal_name:,
        contact_email:,
        contact_phone:,
        commercial_address:,
        user_repository:,
        seller_profile_repository:,
        event_publisher: NullEventPublisher.new,
        clock: -> { Time.current }
      )
        @user_id = user_id
        @display_name = display_name
        @description = description
        @document_type = document_type
        @document_number = document_number
        @legal_name = legal_name
        @contact_email = contact_email
        @contact_phone = contact_phone
        @commercial_address = commercial_address
        @user_repository = user_repository
        @seller_profile_repository = seller_profile_repository
        @event_publisher = event_publisher
        @clock = clock
      end

      def call
        now = @clock.call
        user = find_user!

        validate_user_can_apply!(user)
        validate_existing_seller_profile!
        validate_application_data!

        seller_profile = build_seller_profile(now)
        event = Identity::Events::SellerApplicationSubmitted.new(
          {
            user_id: user.id,
            seller_profile_id: seller_profile.id,
            display_name: seller_profile.display_name,
            document_type: seller_profile.document_type,
            requested_at: now
          },
          occurred_at: now
        )

        @seller_profile_repository.save(seller_profile)
        @event_publisher.publish(event)

        Result.new(seller_profile: seller_profile, events: [ event ])
      end

      private

      def find_user!
        find_record!(
          repository: @user_repository,
          id: @user_id,
          dependency_name: "user_repository",
          not_found_error: UserNotFound,
          not_found_message: "user not found"
        )
      end

      def validate_user_can_apply!(user)
        return if user.can_login?

        raise UserNotAllowed, "user must be active and email confirmed"
      end

      def validate_existing_seller_profile!
        unless @seller_profile_repository.respond_to?(:active_or_pending_for_user?)
          raise MissingDependency, "seller_profile_repository must respond to active_or_pending_for_user?"
        end

        return unless @seller_profile_repository.active_or_pending_for_user?(@user_id)

        raise SellerProfileAlreadyExists, "user already has an active or pending seller profile"
      end

      def validate_application_data!
        validate_presence!("display_name", @display_name)
        validate_presence!("legal_name", @legal_name)
        validate_presence!("contact_phone", @contact_phone)
        validate_contact_email!
        validate_document!
        validate_commercial_address!
      end

      def validate_contact_email!
        email = @contact_email.to_s.strip.downcase
        raise InvalidSellerApplication, "contact_email is invalid" unless email.match?(URI::MailTo::EMAIL_REGEXP)

        @contact_email = email
      end

      def validate_document!
        unless Identity::Entities::SellerProfile::VALID_DOCUMENT_TYPES.include?(@document_type)
          raise InvalidDocument, "document_type must be one of: #{Identity::Entities::SellerProfile::VALID_DOCUMENT_TYPES.join(', ')}"
        end

        @document_number = digits_only(@document_number)
        expected_length = @document_type == Identity::Entities::SellerProfile::DOC_TYPE_CPF ? 11 : 14
        return if @document_number.length == expected_length

        raise InvalidDocument, "document_number is invalid for #{@document_type}"
      end

      def validate_commercial_address!
        unless @commercial_address.respond_to?(:key?)
          raise InvalidSellerApplication, "commercial_address cannot be nil or empty"
        end

        REQUIRED_ADDRESS_FIELDS.each do |field|
          validate_presence!("commercial_address.#{field}", @commercial_address[field] || @commercial_address[field.to_sym])
        end
      end

      def validate_presence!(field_name, value)
        return unless blank?(value)

        raise InvalidSellerApplication, "#{field_name} cannot be nil or empty"
      end

      def blank?(value)
        value.nil? ||
          (value.is_a?(String) && value.strip.empty?) ||
          (value.respond_to?(:empty?) && value.empty?)
      end

      def digits_only(value)
        value.to_s.gsub(/\D/, "")
      end

      def build_seller_profile(now)
        Identity::Entities::SellerProfile.new(
          user_id: @user_id,
          display_name: @display_name.to_s.strip,
          description: @description,
          status: Identity::Entities::SellerProfile::PENDING_REVIEW,
          document_type: @document_type,
          document_number: @document_number,
          legal_name: @legal_name.to_s.strip,
          contact_email: @contact_email,
          contact_phone: @contact_phone.to_s.strip,
          commercial_address: @commercial_address,
          requested_at: now,
          created_at: now,
          updated_at: now
        )
      end

      class NullEventPublisher
        def publish(event)
          true
        end
      end
    end
  end
end
