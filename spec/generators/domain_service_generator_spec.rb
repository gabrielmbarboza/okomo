# frozen_string_literal: true

require 'rails_helper'
require_relative '../../spec/support/generators_helper'
require_relative '../../lib/generators/domain_service/domain_service_generator'

describe 'Domain Service Generator' do
  include GeneratorsHelper

  let(:generator) { nil }

  after do
    cleanup_generator(generator) if generator
  end

  context 'when generating a domain service' do
    let(:domain) { 'Orders' }
    let(:service_name) { 'CreateOrder' }

    it 'creates the service file in the correct directory' do
      generator = run_generator(DomainService::DomainServiceGenerator, [service_name, domain])

      expect(file_exists?(generator, 'app/domains/orders/services/create_order.rb')).to be true
    end

    it 'generates the correct module structure' do
      generator = run_generator(DomainService::DomainServiceGenerator, [service_name, domain])

      content = read_generated_file(generator, 'app/domains/orders/services/create_order.rb')

      expect(content).to include('module Orders')
      expect(content).to include('module Services')
    end

    it 'generates the class with correct inheritance' do
      generator = run_generator(DomainService::DomainServiceGenerator, [service_name, domain])

      content = read_generated_file(generator, 'app/domains/orders/services/create_order.rb')

      expect(content).to include('class CreateOrder < Shared::Services::BaseService')
    end

    it 'generates the call method stub' do
      generator = run_generator(DomainService::DomainServiceGenerator, [service_name, domain])

      content = read_generated_file(generator, 'app/domains/orders/services/create_order.rb')

      expect(content).to include('def call')
      expect(content).to include('raise NotImplementedError')
    end

    it 'generates frozen_string_literal directive' do
      generator = run_generator(DomainService::DomainServiceGenerator, [service_name, domain])

      content = read_generated_file(generator, 'app/domains/orders/services/create_order.rb')

      expect(content).to start_with('# frozen_string_literal: true')
    end
  end

  context 'when using different service and domain names' do
    it 'generates underscored file names from camelized service names' do
      generator = run_generator(DomainService::DomainServiceGenerator, ['CancelOrder', 'Orders'])

      expect(file_exists?(generator, 'app/domains/orders/services/cancel_order.rb')).to be true
    end

    it 'handles different domain names' do
      generator = run_generator(DomainService::DomainServiceGenerator, ['ProcessPayment', 'Payments'])

      expect(file_exists?(generator, 'app/domains/payments/services/process_payment.rb')).to be true

      content = read_generated_file(generator, 'app/domains/payments/services/process_payment.rb')
      expect(content).to include('module Payments')
    end

    it 'generates correct class names from different inputs' do
      generator = run_generator(DomainService::DomainServiceGenerator, ['FulfillOrder', 'Shipping'])

      content = read_generated_file(generator, 'app/domains/shipping/services/fulfill_order.rb')

      expect(content).to include('class FulfillOrder < Shared::Services::BaseService')
    end
  end
end
