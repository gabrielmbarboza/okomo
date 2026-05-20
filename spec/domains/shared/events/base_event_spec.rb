# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Shared::Events::BaseEvent do
  include ActiveSupport::Testing::TimeHelpers

  let(:occurred_at) { Time.zone.parse('2026-05-20 15:45:00') }
  let(:payload) do
    {
      user_id: SecureRandom.uuid,
      roles: [ 'buyer' ]
    }
  end

  describe '#initialize' do
    it 'sets payload and occurred_at' do
      event = described_class.new(payload, occurred_at: occurred_at)

      expect(event.payload).to eq(payload)
      expect(event.occurred_at).to eq(occurred_at)
    end

    it 'uses an empty payload by default' do
      event = described_class.new(occurred_at: occurred_at)

      expect(event.payload).to eq({})
      expect(event.occurred_at).to eq(occurred_at)
    end

    it 'uses current time as default occurred_at' do
      travel_to(occurred_at) do
        event = described_class.new(payload)

        expect(event.occurred_at).to eq(occurred_at)
      end
    end

    it 'freezes the payload' do
      event = described_class.new(payload, occurred_at: occurred_at)

      expect(event.payload).to be_frozen
    end

    it 'freezes the event instance' do
      event = described_class.new(payload, occurred_at: occurred_at)

      expect(event).to be_frozen
    end
  end

  describe 'immutability' do
    it 'prevents replacing instance variables' do
      event = described_class.new(payload, occurred_at: occurred_at)

      expect {
        event.instance_variable_set(:@payload, {})
      }.to raise_error(FrozenError)
    end

    it 'prevents adding new keys to payload' do
      event = described_class.new(payload, occurred_at: occurred_at)

      expect {
        event.payload[:new_key] = 'new-value'
      }.to raise_error(FrozenError)
    end
  end

  describe 'inheritance' do
    let(:event_class) do
      Class.new(described_class)
    end

    it 'allows concrete domain events to inherit the base contract' do
      event = event_class.new(payload, occurred_at: occurred_at)

      expect(event).to be_a(described_class)
      expect(event.payload).to eq(payload)
      expect(event.occurred_at).to eq(occurred_at)
      expect(event).to be_frozen
    end
  end
end
