# frozen_string_literal: true

module Catalog
  module Services
    class CreateVariant < Shared::Services::BaseService
      Error = Catalog::Errors::Error
      ProductNotFound = Catalog::Errors::ProductNotFound
      InvalidVariant = Catalog::Errors::InvalidVariant
      InvalidSku = Catalog::Errors::InvalidSku
      DuplicateSku = Catalog::Errors::DuplicateSku
      InvalidPrice = Catalog::Errors::InvalidPrice
      InvalidDimensions = Catalog::Errors::InvalidDimensions

      POSITIVE_WHEN_PRESENT_ATTRIBUTES = %i[weight_grams height_cm width_cm length_cm].freeze

      Result = Struct.new(:variant, :events, keyword_init: true) do
        def success?
          true
        end
      end

      def initialize(
        product_id:,
        name:,
        sku:,
        price:,
        weight_grams: nil,
        height_cm: nil,
        width_cm: nil,
        length_cm: nil,
        product_repository:,
        variant_repository:,
        event_publisher: NullEventPublisher.new,
        clock: -> { Time.current }
      )
        @product_id = product_id
        @name = name
        @sku = sku
        @price = price
        @weight_grams = weight_grams
        @height_cm = height_cm
        @width_cm = width_cm
        @length_cm = length_cm
        @product_repository = product_repository
        @variant_repository = variant_repository
        @event_publisher = event_publisher
        @clock = clock
      end

      def call
        now = @clock.call
        product = find_product!

        validate_presence!(InvalidVariant, :name, @name)
        validate_presence!(InvalidSku, :sku, @sku)
        validate_price!
        validate_dimensions!
        validate_unique_sku!(product.id)

        variant = Catalog::Entities::Variant.new(
          product_id: product.id,
          name: @name,
          sku: @sku,
          price: @price,
          weight_grams: @weight_grams,
          height_cm: @height_cm,
          width_cm: @width_cm,
          length_cm: @length_cm,
          created_at: now,
          updated_at: now
        )
        event = Catalog::Events::VariantCreated.new(
          {
            variant_id: variant.id,
            product_id: variant.product_id,
            sku: variant.sku,
            created_at: variant.created_at
          },
          occurred_at: now
        )

        @variant_repository.save(variant)
        @event_publisher.publish(event)

        Result.new(variant: variant, events: [ event ])
      end

      private

      def find_product!
        product = @product_repository.find_by_id(@product_id)
        raise ProductNotFound, "product not found" if product.nil?

        product
      end

      def validate_presence!(error_class, attribute_name, value)
        return if value.present?

        raise error_class, "#{attribute_name} cannot be nil or empty"
      end

      def validate_price!
        return if @price && @price > 0

        raise InvalidPrice, "price must be greater than zero"
      end

      def validate_dimensions!
        POSITIVE_WHEN_PRESENT_ATTRIBUTES.each do |attribute_name|
          value = instance_variable_get(:"@#{attribute_name}")
          next if value.nil?

          raise InvalidDimensions, "#{attribute_name} must be positive" if value <= 0
        end
      end

      def validate_unique_sku!(product_id)
        return unless @variant_repository.sku_exists_for_product?(product_id, @sku)

        raise DuplicateSku, "sku already exists for this product"
      end

      class NullEventPublisher
        def publish(event)
          true
        end
      end
    end
  end
end
