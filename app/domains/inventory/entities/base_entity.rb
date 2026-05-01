# frozen_string_literal: true

module Inventory
  module Entities
    class BaseEntity
      def initialize(**attributes)
        attributes.each do |key, value|
          instance_variable_set(:"@#{key}", value)
        end
      end
    end
  end
end
