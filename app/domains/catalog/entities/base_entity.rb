# frozen_string_literal: true

module Catalog
  module Entities
    # Base class for Catalog domain entities (POROs).
    #
    # Entities represent core business concepts with identity.
    # They are NOT ActiveRecord models — they are plain Ruby objects
    # that encapsulate domain behavior and rules.
    #
    # Usage:
    #   class Catalog::Entities::Product < Catalog::Entities::BaseEntity
    #     attr_reader :id, :name, :description
    #
    #     def initialize(id:, name:, description:)
    #       @id = id
    #       @name = name
    #       @description = description
    #     end
    #   end
    #
    class BaseEntity
      def initialize(**attributes)
        attributes.each do |key, value|
          instance_variable_set(:"@#{key}", value)
        end
      end
    end
  end
end
