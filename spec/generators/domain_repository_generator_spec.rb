# frozen_string_literal: true

require 'rails_helper'
require_relative '../../spec/support/generators_helper'
require_relative '../../lib/generators/domain_repository/domain_repository_generator'

describe 'Domain Repository Generator' do
  include GeneratorsHelper

  let(:generator) { nil }

  after do
    cleanup_generator(generator) if generator
  end

  context 'when generating a domain repository' do
    let(:domain) { 'Orders' }
    let(:repository_name) { 'OrderRepository' }

    it 'creates the repository file in the correct directory' do
      generator = run_generator(DomainRepository::DomainRepositoryGenerator, [repository_name, domain])

      expect(file_exists?(generator, 'app/domains/orders/repositories/order_repository.rb')).to be true
    end

    it 'generates the correct module structure' do
      generator = run_generator(DomainRepository::DomainRepositoryGenerator, [repository_name, domain])

      content = read_generated_file(generator, 'app/domains/orders/repositories/order_repository.rb')

      expect(content).to include('module Orders')
      expect(content).to include('module Repositories')
    end

    it 'generates the class definition' do
      generator = run_generator(DomainRepository::DomainRepositoryGenerator, [repository_name, domain])

      content = read_generated_file(generator, 'app/domains/orders/repositories/order_repository.rb')

      expect(content).to include('class OrderRepository')
    end

    it 'generates frozen_string_literal directive' do
      generator = run_generator(DomainRepository::DomainRepositoryGenerator, [repository_name, domain])

      content = read_generated_file(generator, 'app/domains/orders/repositories/order_repository.rb')

      expect(content).to start_with('# frozen_string_literal: true')
    end
  end

  context 'when using different repository and domain names' do
    it 'generates underscored file names from camelized repository names' do
      generator = run_generator(DomainRepository::DomainRepositoryGenerator, ['OrderItemRepository', 'Orders'])

      expect(file_exists?(generator, 'app/domains/orders/repositories/order_item_repository.rb')).to be true
    end

    it 'handles different domain names' do
      generator = run_generator(DomainRepository::DomainRepositoryGenerator, ['PaymentRepository', 'Payments'])

      expect(file_exists?(generator, 'app/domains/payments/repositories/payment_repository.rb')).to be true

      content = read_generated_file(generator, 'app/domains/payments/repositories/payment_repository.rb')
      expect(content).to include('module Payments')
    end

    it 'generates correct class names from different inputs' do
      generator = run_generator(DomainRepository::DomainRepositoryGenerator, ['ProductRepository', 'Inventory'])

      content = read_generated_file(generator, 'app/domains/inventory/repositories/product_repository.rb')

      expect(content).to include('class ProductRepository')
    end

    it 'generates repository class without base class inheritance' do
      generator = run_generator(DomainRepository::DomainRepositoryGenerator, ['UserRepository', 'Identity'])

      content = read_generated_file(generator, 'app/domains/identity/repositories/user_repository.rb')

      expect(content).to include('class UserRepository')
      expect(content).not_to include('class UserRepository <')
    end
  end
end
