# frozen_string_literal: true

module Catalog
  module Services
    # Base class for Catalog domain services.
    #
    # All services in this domain should inherit from this class.
    # Services encapsulate business operations and orchestrate domain logic.
    #
    # Usage:
    #   class Catalog::Services::CreateProduct < Catalog::Services::BaseService
    #     def call(params)
    #       # business logic here
    #     end
    #   end
    #
    class BaseService
      def self.call(...)
        new(...).call
      end
    end
  end
end
