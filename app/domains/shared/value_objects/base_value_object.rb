# frozen_string_literal: true

module Shared
  module ValueObjects
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
        [self.class, *instance_variables.map { |var| instance_variable_get(var) }].hash
      end
    end
  end
end