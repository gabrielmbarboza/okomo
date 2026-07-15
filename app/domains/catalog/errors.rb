# frozen_string_literal: true

module Catalog
  module Errors
    class Error < StandardError; end

    class MissingDependency < Error; end

    class ProductNotFound < Error; end
    class VariantNotFound < Error; end

    class InvalidProduct < Error; end
    class InvalidVariant < Error; end
    class InvalidSku < Error; end
    class DuplicateSku < Error; end
    class InvalidPrice < Error; end
    class InvalidDimensions < Error; end

    class InvalidProductState < Error; end
    class ProductNotPublishable < Error; end
  end
end
