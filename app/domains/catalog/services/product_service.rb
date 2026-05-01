# frozen_string_literal: true

module Catalog
  module Services
    # ProductService handles business logic for product operations
    # 
    # This service coordinates between entities and repositories
    # to execute use cases while maintaining business rules
    #
    class ProductService
      # Initialize with dependencies (could be repositories, external services, etc.)
      def initialize(product_repository: nil)
        @product_repository = product_repository
      end

      # Create a new product with business validation
      def create_product(params)
        # Generate UUID for new product
        product_id = SecureRandom.uuid
        
        # Create entity with validation
        product = Catalog::Entities::Product.new(
          id: product_id,
          name: params[:name],
          description: params[:description],
          price: params[:price],
          sku: params[:sku],
          status: params[:status] || 'active'
        )

        # Check for existing SKU
        raise ArgumentError, 'SKU already exists' if sku_exists?(product.sku)

        # Save product (would use repository in real implementation)
        save_product(product)

        # Return created product
        product
      end

      # Update an existing product
      def update_product(product_id, params)
        product = find_product(product_id)
        raise ArgumentError, 'Product not found' unless product

        # Update attributes with validation
        if params[:price].present?
          product.update_price(params[:price])
        end

        if params[:status].present?
          case params[:status]
          when 'active'
            product.activate!
          when 'inactive'
            product.deactivate!
          when 'discontinued'
            product.discontinue!
          else
            raise ArgumentError, 'Invalid status'
          end
        end

        # Update other attributes
        if params[:name].present?
          # Would need to create a new entity or add update methods
          # For now, we'll just return the updated product
        end

        save_product(product)
        product
      end

      # Get product by ID
      def get_product(product_id)
        find_product(product_id)
      end

      # List all active products
      def list_active_products
        # Would use repository to filter
        all_products.select(&:active?)
      end

      # Search products by name or SKU
      def search_products(query)
        return [] if query.nil? || query.strip.empty?
        
        search_term = query.downcase
        all_products.select do |product|
          product.name.downcase.include?(search_term) || 
          product.sku.downcase.include?(search_term)
        end
      end

      # Deactivate product (soft delete)
      def deactivate_product(product_id)
        product = find_product(product_id)
        raise ArgumentError, 'Product not found' unless product
        
        product.deactivate!
        save_product(product)
        product
      end

      # Check if SKU exists
      def sku_exists?(sku)
        all_products.any? { |product| product.sku == sku }
      end

      private

      # Repository methods (mocked for demo)
      # In real implementation, these would use ActiveRecord or other persistence

      def save_product(product)
        # Mock implementation - would save to database
        Rails.logger.info "Saving product: #{product.id} - #{product.name}"
        products = all_products
        existing_index = products.find_index { |p| p.id == product.id }
        
        if existing_index
          products[existing_index] = product
        else
          products << product
        end
        
        # Store in memory for demo
        Rails.cache.write("catalog_products", products, expires_in: 1.hour)
      end

      def find_product(product_id)
        all_products.find { |product| product.id == product_id }
      end

      def all_products
        # Mock data store - would use repository
        Rails.cache.fetch("catalog_products", expires_in: 1.hour) do
          # Create some sample products for demo
          [
            Catalog::Entities::Product.new(
              id: SecureRandom.uuid,
              name: 'Sample Product 1',
              description: 'This is a sample product for demonstration',
              price: 99.99,
              sku: 'SAMPLE-001'
            ),
            Catalog::Entities::Product.new(
              id: SecureRandom.uuid,
              name: 'Sample Product 2',
              description: 'Another sample product',
              price: 149.99,
              sku: 'SAMPLE-002'
            )
          ]
        end
      end
    end
  end
end
