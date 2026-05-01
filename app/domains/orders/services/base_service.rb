# frozen_string_literal: true

module Orders
  module Services
    class BaseService
      def self.call(...)
        new(...).call
      end
    end
  end
end
