# frozen_string_literal: true

require 'rails_helper'
require_relative '../../spec/support/generators_helper'
require_relative '../../lib/generators/domain/domain_generator'

describe 'Domain Generator' do
  include GeneratorsHelper

  let(:generator) { nil }

  after do
    cleanup_generator(generator) if generator
  end

  context 'when generating a new domain' do
    let(:domain_name) { 'Orders' }

    it 'creates the domain directory structure' do
      generator = run_generator(Domain::DomainGenerator, [domain_name])

      expect(directory_exists?(generator, 'app/domains/orders')).to be true
      expect(directory_exists?(generator, 'app/domains/orders/entities')).to be true
      expect(directory_exists?(generator, 'app/domains/orders/services')).to be true
      expect(directory_exists?(generator, 'app/domains/orders/repositories')).to be true
      expect(directory_exists?(generator, 'app/domains/orders/value_objects')).to be true
      expect(directory_exists?(generator, 'app/domains/orders/events')).to be true
      expect(directory_exists?(generator, 'app/domains/orders/specifications')).to be true
      expect(directory_exists?(generator, 'app/domains/orders/policies')).to be true
    end

    it 'creates the domain module file' do
      generator = run_generator(Domain::DomainGenerator, [domain_name])

      expect(file_exists?(generator, 'app/domains/orders/orders.rb')).to be true
    end

    it 'generates the correct module definition in the domain file' do
      generator = run_generator(Domain::DomainGenerator, [domain_name])

      content = read_generated_file(generator, 'app/domains/orders/orders.rb')

      expect(content).to include('module Orders')
      expect(content).to include('end')
    end

    it 'generates frozen_string_literal directive' do
      generator = run_generator(Domain::DomainGenerator, [domain_name])

      content = read_generated_file(generator, 'app/domains/orders/orders.rb')

      expect(content).to start_with('# frozen_string_literal: true')
    end
  end

  context 'when using different domain names' do
    it 'handles underscored domain names' do
      generator = run_generator(Domain::DomainGenerator, ['inventory_management'])

      expect(directory_exists?(generator, 'app/domains/inventory_management')).to be true
      expect(file_exists?(generator, 'app/domains/inventory_management/inventory_management.rb')).to be true
    end

    it 'handles camelized domain names' do
      generator = run_generator(Domain::DomainGenerator, ['PaymentGateway'])

      expect(directory_exists?(generator, 'app/domains/payment_gateway')).to be true
      expect(file_exists?(generator, 'app/domains/payment_gateway/payment_gateway.rb')).to be true
    end
  end
end
