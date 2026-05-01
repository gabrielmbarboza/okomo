# frozen_string_literal: true

module Catalog
  module ValueObjects
    # Base class for Catalog domain value objects.
    #
    # Value objects are immutable and compared by value, not identity.
    # They represent descriptive aspects of the domain with no conceptual identity.
    #
    # Usage:
    #   class Catalog::ValueObjects::Money < Catalog::ValueObjects::BaseValueObject
    #     attr_reader :amount, :currency
    #
    #     def initialize(amount:, currency: "BRL")
    #       @amount = amount
    #       @currency = currency
    #       freeze
    #     end
    #   end
    #
    class BaseValueObject
      def initialize(**attributes)
        attributes.each do |key, value|
          instance_variable_set(:"@#{key}", value)
        end
        freeze
      end

      def ==(other)
        self.class == other.class &&
          instance_variables.all? do |var|
            instance_variable_get(var) == other.instance_variable_get(var)
          end
      end
      alias_method :eql?, :==

      def hash
        instance_variables.map { |var| instance_variable_get(var) }.hash
      end
    end
  end
end
