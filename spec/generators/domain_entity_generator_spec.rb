# frozen_string_literal: true

require 'rails_helper'
require_relative '../../spec/support/generators_helper'
require_relative '../../lib/generators/domain_entity/domain_entity_generator'

describe 'Domain Entity Generator' do
  include GeneratorsHelper

  let(:generator) { nil }

  after do
    cleanup_generator(generator) if generator
  end

  context 'when generating a domain entity' do
    let(:domain) { 'Orders' }
    let(:entity_name) { 'Order' }

    it 'creates the entity file in the correct directory' do
      generator = run_generator(DomainEntity::DomainEntityGenerator, [entity_name, domain])

      expect(file_exists?(generator, 'app/domains/orders/entities/order.rb')).to be true
    end

    it 'generates the correct module structure' do
      generator = run_generator(DomainEntity::DomainEntityGenerator, [entity_name, domain])

      content = read_generated_file(generator, 'app/domains/orders/entities/order.rb')

      expect(content).to include('module Orders')
      expect(content).to include('module Entities')
    end

    it 'generates the class with correct inheritance' do
      generator = run_generator(DomainEntity::DomainEntityGenerator, [entity_name, domain])

      content = read_generated_file(generator, 'app/domains/orders/entities/order.rb')

      expect(content).to include('class Order < Shared::Entities::BaseEntity')
    end

    it 'generates frozen_string_literal directive' do
      generator = run_generator(DomainEntity::DomainEntityGenerator, [entity_name, domain])

      content = read_generated_file(generator, 'app/domains/orders/entities/order.rb')

      expect(content).to start_with('# frozen_string_literal: true')
    end
  end

  context 'when using different entity and domain names' do
    it 'generates underscored file names from camelized entity names' do
      generator = run_generator(DomainEntity::DomainEntityGenerator, ['OrderItem', 'Orders'])

      expect(file_exists?(generator, 'app/domains/orders/entities/order_item.rb')).to be true
    end

    it 'handles different domain names' do
      generator = run_generator(DomainEntity::DomainEntityGenerator, ['Product', 'Inventory'])

      expect(file_exists?(generator, 'app/domains/inventory/entities/product.rb')).to be true

      content = read_generated_file(generator, 'app/domains/inventory/entities/product.rb')
      expect(content).to include('module Inventory')
    end

    it 'generates correct class names from different inputs' do
      generator = run_generator(DomainEntity::DomainEntityGenerator, ['PaymentMethod', 'Payments'])

      content = read_generated_file(generator, 'app/domains/payments/entities/payment_method.rb')

      expect(content).to include('class PaymentMethod < Shared::Entities::BaseEntity')
    end
  end
end
