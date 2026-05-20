# frozen_string_literal: true

module Shared
  module Events
    class BaseEvent
      attr_reader :payload, :occurred_at

      def initialize(payload = {}, occurred_at: Time.current)
        @payload = payload.freeze
        @occurred_at = occurred_at
        freeze
      end
    end
  end
end
