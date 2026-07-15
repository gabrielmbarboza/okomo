# frozen_string_literal: true

module Catalog
  module Services
    class PublishProduct < Shared::Services::BaseService
      Error = Catalog::Errors::Error
      ProductNotFound = Catalog::Errors::ProductNotFound
      InvalidProductState = Catalog::Errors::InvalidProductState
      ProductNotPublishable = Catalog::Errors::ProductNotPublishable

      Result = Struct.new(:product, :events, keyword_init: true) do
        def success?
          true
        end
      end

      def initialize(
        product_id:,
        product_repository:,
        variant_repository:,
        event_publisher: NullEventPublisher.new,
        clock: -> { Time.current }
      )
        @product_id = product_id
        @product_repository = product_repository
        @variant_repository = variant_repository
        @event_publisher = event_publisher
        @clock = clock
      end

      def call
        now = @clock.call
        product = find_product!

        validate_draft!(product)
        validate_description!(product)
        validate_sellable_variant!(product)

        product.publish!(published_at: now)
        event = Catalog::Events::ProductPublished.new(
          {
            product_id: product.id,
            seller_profile_id: product.seller_profile_id,
            published_at: now
          },
          occurred_at: now
        )

        @product_repository.save(product)
        @event_publisher.publish(event)

        Result.new(product: product, events: [ event ])
      end

      private

      def find_product!
        product = @product_repository.find_by_id(@product_id)
        raise ProductNotFound, "product not found" if product.nil?

        product
      end

      def validate_draft!(product)
        raise InvalidProductState, "product must be draft to be published" unless product.draft?
      end

      def validate_description!(product)
        return if product.description.present?

        raise ProductNotPublishable, "product must have a description to be published"
      end

      def validate_sellable_variant!(product)
        variants = @variant_repository.find_by_product_id(product.id)
        return if variants.any?(&:sellable?)

        raise ProductNotPublishable, "product must have at least one sellable variant"
      end

      class NullEventPublisher
        def publish(event)
          true
        end
      end
    end
  end
end
