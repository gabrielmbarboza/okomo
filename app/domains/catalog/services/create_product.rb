# frozen_string_literal: true

module Catalog
  module Services
    class CreateProduct < Shared::Services::BaseService
      Error = Catalog::Errors::Error
      InvalidProduct = Catalog::Errors::InvalidProduct

      Result = Struct.new(:product, :events, keyword_init: true) do
        def success?
          true
        end
      end

      def initialize(
        seller_profile_id:,
        name:,
        description: nil,
        product_repository:,
        event_publisher: NullEventPublisher.new,
        clock: -> { Time.current }
      )
        @seller_profile_id = seller_profile_id
        @name = name
        @description = description
        @product_repository = product_repository
        @event_publisher = event_publisher
        @clock = clock
      end

      def call
        now = @clock.call

        validate_presence!(:seller_profile_id, @seller_profile_id)
        validate_presence!(:name, @name)

        product = Catalog::Entities::Product.new(
          seller_profile_id: @seller_profile_id,
          name: @name,
          description: @description,
          created_at: now,
          updated_at: now
        )
        event = Catalog::Events::ProductCreated.new(
          {
            product_id: product.id,
            seller_profile_id: product.seller_profile_id,
            created_at: product.created_at
          },
          occurred_at: now
        )

        @product_repository.save(product)
        @event_publisher.publish(event)

        Result.new(product: product, events: [ event ])
      end

      private

      def validate_presence!(attribute_name, value)
        return if value.present?

        raise InvalidProduct, "#{attribute_name} cannot be nil or empty"
      end

      class NullEventPublisher
        def publish(event)
          true
        end
      end
    end
  end
end
