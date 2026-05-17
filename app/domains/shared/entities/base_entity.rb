# frozen_string_literal: true

module Shared
  module Entities
    class BaseEntity
      class << self
        def attributes(*names)
          names.each { |name| attribute(name) }
        end

        def attribute(name, default: nil)
          normalized_name = name.to_sym

          @attribute_definitions ||= {}
          @attribute_definitions[normalized_name] = { default: default }
          attr_accessor normalized_name
        end

        def validates(attribute_name, options = {})
          @validations ||= []
          @validations << {
            attribute: attribute_name.to_sym,
            options: options
          }
        end

        def attribute_definitions
          inherited = superclass.respond_to?(:attribute_definitions) ? superclass.attribute_definitions : {}

          inherited.merge(@attribute_definitions || {})
        end

        def attribute_names
          attribute_definitions.keys
        end

        def validations
          inherited = superclass.respond_to?(:validations) ? superclass.validations : []

          inherited + (@validations ||= [])
        end
      end

      def initialize(**attrs)
        assign_declared_attributes(attrs)
        assign_extra_attributes(attrs)
        validate!
      end

      def validate!
        self.class.validations.each do |validation|
          attribute_name = validation.fetch(:attribute)
          options = validation.fetch(:options)
          value = public_send(attribute_name)

          validate_presence!(attribute_name, value, options[:presence]) if options.key?(:presence)
          validate_inclusion!(attribute_name, value, options[:inclusion]) if options.key?(:inclusion)
        end

        self
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

      private

      def assign_declared_attributes(attrs)
        self.class.attribute_definitions.each do |name, definition|
          value = attrs.key?(name) ? attrs[name] : default_value(definition[:default])

          public_send(:"#{name}=", value)
        end
      end

      def assign_extra_attributes(attrs)
        attrs.each do |key, value|
          next if self.class.attribute_definitions.key?(key.to_sym)

          instance_variable_set(:"@#{key}", value)
        end
      end

      def default_value(default)
        return default unless default.respond_to?(:call)

        default.arity.zero? ? default.call : default.call(self)
      end

      def validate_presence!(attribute_name, value, option)
        return unless option
        return unless blank_value?(value)

        raise ArgumentError, validation_message(attribute_name, option, "#{attribute_name} cannot be nil or empty")
      end

      def validate_inclusion!(attribute_name, value, option)
        return if value.nil?

        collection = option.fetch(:in)
        return if collection.include?(value)

        default_message = "#{attribute_name} must be one of: #{collection.join(', ')}"

        raise ArgumentError, validation_message(attribute_name, option, default_message)
      end

      def validation_message(attribute_name, option, default_message)
        return default_message unless option.respond_to?(:key?)

        option.fetch(:message, default_message)
      end

      def blank_value?(value)
        value.nil? ||
          (value.is_a?(String) && value.strip.empty?) ||
          (value.respond_to?(:empty?) && value.empty?)
      end
    end
  end
end
