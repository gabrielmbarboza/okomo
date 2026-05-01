# frozen_string_literal: true

module Payments
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
