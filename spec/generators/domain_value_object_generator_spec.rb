# frozen_string_literal: true

require 'rails_helper'
require_relative '../../spec/support/generators_helper'
require_relative '../../lib/generators/domain_value_object/domain_value_object_generator'

describe 'Domain Value Object Generator' do
  include GeneratorsHelper

  let(:generator) { nil }

  after do
    cleanup_generator(generator) if generator
  end

  context 'when generating a domain value object' do
    let(:domain) { 'Orders' }
    let(:value_object_name) { 'Money' }

    it 'creates the value object file in the correct directory' do
      generator = run_generator(DomainValueObject::DomainValueObjectGenerator, [value_object_name, domain])

      expect(file_exists?(generator, 'app/domains/orders/value_objects/money.rb')).to be true
    end

    it 'generates the correct module structure' do
      generator = run_generator(DomainValueObject::DomainValueObjectGenerator, [value_object_name, domain])

      content = read_generated_file(generator, 'app/domains/orders/value_objects/money.rb')

      expect(content).to include('module Orders')
      expect(content).to include('module ValueObjects')
    end

    it 'generates the class with correct inheritance' do
      generator = run_generator(DomainValueObject::DomainValueObjectGenerator, [value_object_name, domain])

      content = read_generated_file(generator, 'app/domains/orders/value_objects/money.rb')

      expect(content).to include('class Money < Shared::ValueObjects::BaseValueObject')
    end

    it 'generates frozen_string_literal directive' do
      generator = run_generator(DomainValueObject::DomainValueObjectGenerator, [value_object_name, domain])

      content = read_generated_file(generator, 'app/domains/orders/value_objects/money.rb')

      expect(content).to start_with('# frozen_string_literal: true')
    end
  end

  context 'when using different value object and domain names' do
    it 'generates underscored file names from camelized value object names' do
      generator = run_generator(DomainValueObject::DomainValueObjectGenerator, ['OrderStatus', 'Orders'])

      expect(file_exists?(generator, 'app/domains/orders/value_objects/order_status.rb')).to be true
    end

    it 'handles different domain names' do
      generator = run_generator(DomainValueObject::DomainValueObjectGenerator, ['CurrencyCode', 'Payments'])

      expect(file_exists?(generator, 'app/domains/payments/value_objects/currency_code.rb')).to be true

      content = read_generated_file(generator, 'app/domains/payments/value_objects/currency_code.rb')
      expect(content).to include('module Payments')
    end

    it 'generates correct class names from different inputs' do
      generator = run_generator(DomainValueObject::DomainValueObjectGenerator, ['Quantity', 'Inventory'])

      content = read_generated_file(generator, 'app/domains/inventory/value_objects/quantity.rb')

      expect(content).to include('class Quantity < Shared::ValueObjects::BaseValueObject')
    end
  end
end
