# frozen_string_literal: true

require 'rails_helper'
require_relative '../../spec/support/generators_helper'
require_relative '../../lib/generators/domain_event/domain_event_generator'

describe 'Domain Event Generator' do
  include GeneratorsHelper

  let(:generator) { nil }

  after do
    cleanup_generator(generator) if generator
  end

  context 'when generating a domain event' do
    let(:domain) { 'Orders' }
    let(:event_name) { 'OrderCreated' }

    it 'creates the event file in the correct directory' do
      generator = run_generator(DomainEvent::DomainEventGenerator, [event_name, domain])

      expect(file_exists?(generator, 'app/domains/orders/events/order_created.rb')).to be true
    end

    it 'generates the correct module structure' do
      generator = run_generator(DomainEvent::DomainEventGenerator, [event_name, domain])

      content = read_generated_file(generator, 'app/domains/orders/events/order_created.rb')

      expect(content).to include('module Orders')
      expect(content).to include('module Events')
    end

    it 'generates the class definition' do
      generator = run_generator(DomainEvent::DomainEventGenerator, [event_name, domain])

      content = read_generated_file(generator, 'app/domains/orders/events/order_created.rb')

      expect(content).to include('class OrderCreated')
    end

    it 'generates attr_reader for payload and occurred_at' do
      generator = run_generator(DomainEvent::DomainEventGenerator, [event_name, domain])

      content = read_generated_file(generator, 'app/domains/orders/events/order_created.rb')

      expect(content).to include('attr_reader :payload, :occurred_at')
    end

    it 'generates initialize method with payload parameter' do
      generator = run_generator(DomainEvent::DomainEventGenerator, [event_name, domain])

      content = read_generated_file(generator, 'app/domains/orders/events/order_created.rb')

      expect(content).to include('def initialize(payload = {})')
    end

    it 'sets occurred_at to Time.current' do
      generator = run_generator(DomainEvent::DomainEventGenerator, [event_name, domain])

      content = read_generated_file(generator, 'app/domains/orders/events/order_created.rb')

      expect(content).to include('@occurred_at = Time.current')
    end

    it 'freezes the event instance' do
      generator = run_generator(DomainEvent::DomainEventGenerator, [event_name, domain])

      content = read_generated_file(generator, 'app/domains/orders/events/order_created.rb')

      expect(content).to include('freeze')
    end

    it 'generates frozen_string_literal directive' do
      generator = run_generator(DomainEvent::DomainEventGenerator, [event_name, domain])

      content = read_generated_file(generator, 'app/domains/orders/events/order_created.rb')

      expect(content).to start_with('# frozen_string_literal: true')
    end
  end

  context 'when using different event and domain names' do
    it 'generates underscored file names from camelized event names' do
      generator = run_generator(DomainEvent::DomainEventGenerator, ['OrderCancelled', 'Orders'])

      expect(file_exists?(generator, 'app/domains/orders/events/order_cancelled.rb')).to be true
    end

    it 'handles different domain names' do
      generator = run_generator(DomainEvent::DomainEventGenerator, ['PaymentProcessed', 'Payments'])

      expect(file_exists?(generator, 'app/domains/payments/events/payment_processed.rb')).to be true

      content = read_generated_file(generator, 'app/domains/payments/events/payment_processed.rb')
      expect(content).to include('module Payments')
    end

    it 'generates correct class names from different inputs' do
      generator = run_generator(DomainEvent::DomainEventGenerator, ['InventoryAdjusted', 'Inventory'])

      content = read_generated_file(generator, 'app/domains/inventory/events/inventory_adjusted.rb')

      expect(content).to include('class InventoryAdjusted')
    end

    it 'generates complete event template for all event types' do
      generator = run_generator(DomainEvent::DomainEventGenerator, ['UserRegistered', 'Identity'])

      content = read_generated_file(generator, 'app/domains/identity/events/user_registered.rb')

      expect(content).to include('module Identity')
      expect(content).to include('module Events')
      expect(content).to include('class UserRegistered')
      expect(content).to include('attr_reader :payload, :occurred_at')
      expect(content).to include('def initialize(payload = {})')
      expect(content).to include('@occurred_at = Time.current')
      expect(content).to include('freeze')
    end
  end
end
