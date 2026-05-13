# frozen_string_literal: true

module Shared
  module Services
    class BaseService
      def self.call(...)
        new(...).call
      end

      def call
        raise NotImplementedError, 'Subclasses must implement this method'
      end
    end
  end
end