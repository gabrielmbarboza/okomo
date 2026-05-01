# frozen_string_literal: true

module Catalog
  module Entities
    # Product entity representing a catalog product
    # 
    # This is a pure Ruby object (PORO) that encapsulates
    # business logic and rules for products
    #
    class Product < BaseEntity
      attr_reader :id, :name, :description, :price, :sku, :status, :created_at, :updated_at

      VALID_STATUSES = %w[active inactive discontinued].freeze
      MIN_PRICE = 0.01
      MAX_PRICE = 999_999.99

      def initialize(id:, name:, description:, price:, sku:, status: 'active', created_at: nil, updated_at: nil)
        super(
          id: id,
          name: name,
          description: description,
          price: price,
          sku: sku,
          status: status,
          created_at: created_at || Time.current,
          updated_at: updated_at || Time.current
        )

        validate!
      end

      # Business logic methods
      
      def activate!
        @status = 'active'
        @updated_at = Time.current
      end

      def deactivate!
        @status = 'inactive'
        @updated_at = Time.current
      end

      def discontinue!
        @status = 'discontinued'
        @updated_at = Time.current
      end

      def active?
        status == 'active'
      end

      def inactive?
        status == 'inactive'
      end

      def discontinued?
        status == 'discontinued'
      end

      def update_price(new_price)
        raise ArgumentError, 'Invalid price' unless valid_price?(new_price)
        
        @price = new_price
        @updated_at = Time.current
      end

      # Convert entity to hash for JSON serialization
      def to_h
        {
          id: id,
          name: name,
          description: description,
          price: price,
          sku: sku,
          status: status,
          created_at: created_at,
          updated_at: updated_at
        }
      end

      # Domain rules validation
      private

      def validate!
        validate_name!
        validate_description!
        validate_price!
        validate_sku!
        validate_status!
      end

      def validate_name!
        raise ArgumentError, 'Name cannot be blank' if name.nil? || name.strip.empty?
        raise ArgumentError, 'Name too long (max 255 chars)' if name.length > 255
      end

      def validate_description!
        raise ArgumentError, 'Description cannot be blank' if description.nil? || description.strip.empty?
        raise ArgumentError, 'Description too long (max 1000 chars)' if description.length > 1000
      end

      def validate_price!
        raise ArgumentError, 'Invalid price format' unless price.is_a?(Numeric)
        raise ArgumentError, 'Price must be positive' unless valid_price?(price)
      end

      def validate_price_numeric
        raise ArgumentError, 'Invalid price format' unless price.is_a?(Numeric)
      end

      def valid_price?(price)
        price.is_a?(Numeric) && price >= MIN_PRICE && price <= MAX_PRICE
      end

      def validate_sku!
        raise ArgumentError, 'SKU cannot be blank' if sku.nil? || sku.strip.empty?
        raise ArgumentError, 'Invalid SKU format' unless sku.match?(/\A[A-Z0-9-]{3,20}\z/)
      end

      def validate_status!
        raise ArgumentError, 'Invalid status' unless VALID_STATUSES.include?(status)
      end
    end
  end
end
