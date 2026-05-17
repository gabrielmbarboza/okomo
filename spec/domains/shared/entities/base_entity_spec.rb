# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Shared::Entities::BaseEntity do
  let(:entity_class) do
    Class.new(described_class) do
      attr_reader :id, :name, :email

      def initialize(id: nil, name: nil, email: nil)
        super(id: id, name: name, email: email)
      end
    end
  end

  let(:entity1) { entity_class.new(id: 1, name: 'John', email: 'john@example.com') }
  let(:entity2) { entity_class.new(id: 1, name: 'John', email: 'john@example.com') }
  let(:entity3) { entity_class.new(id: 2, name: 'John', email: 'john@example.com') }
  let(:entity4) { entity_class.new(id: 1, name: 'Jane', email: 'john@example.com') }

  describe '#initialize' do
    it 'sets instance variables from attributes' do
      expect(entity1.id).to eq(1)
      expect(entity1.name).to eq('John')
      expect(entity1.email).to eq('john@example.com')
    end

    it 'handles empty attributes' do
      empty_entity = entity_class.new
      expect(empty_entity.id).to be_nil
      expect(empty_entity.name).to be_nil
      expect(empty_entity.email).to be_nil
    end

    it 'sets multiple attributes correctly' do
      complex_entity = entity_class.new(id: 123, name: 'Alice', email: 'alice@test.com')
      expect(complex_entity.id).to eq(123)
      expect(complex_entity.name).to eq('Alice')
      expect(complex_entity.email).to eq('alice@test.com')
    end
  end

  describe '.attributes' do
    let(:declarative_class) do
      Class.new(described_class) do
        attributes :id, :name
      end
    end

    it 'registra atributos declarados' do
      expect(declarative_class.attribute_names).to eq(%i[id name])
    end

    it 'cria accessors automaticamente' do
      entity = declarative_class.new(id: 1, name: 'John')

      expect(entity.id).to eq(1)
      expect(entity.name).to eq('John')

      entity.name = 'Jane'
      expect(entity.name).to eq('Jane')
    end
  end

  describe '.attribute' do
    it 'registra a definição de um atributo com default literal' do
      declarative_class = Class.new(described_class) do
        attribute :status, default: 'pending'
      end

      expect(declarative_class.attribute_definitions).to eq(
        status: { default: 'pending' }
      )
    end

    it 'aplica default literal quando atributo não é informado' do
      declarative_class = Class.new(described_class) do
        attribute :status, default: 'pending'
      end

      expect(declarative_class.new.status).to eq('pending')
    end

    it 'não substitui valor explicitamente informado por default' do
      declarative_class = Class.new(described_class) do
        attribute :status, default: 'pending'
      end

      expect(declarative_class.new(status: 'active').status).to eq('active')
    end

    it 'avalia default callable por instância' do
      declarative_class = Class.new(described_class) do
        attribute :items, default: -> { [] }
      end

      first = declarative_class.new
      second = declarative_class.new

      first.items << 'item'

      expect(first.items).to eq([ 'item' ])
      expect(second.items).to eq([])
    end

    it 'permite default callable dependente da instância' do
      declarative_class = Class.new(described_class) do
        attribute :created_at, default: -> { Time.zone.parse('2026-05-17 10:00:00') }
        attribute :updated_at, default: ->(entity) { entity.created_at }
      end

      entity = declarative_class.new

      expect(entity.updated_at).to eq(entity.created_at)
    end
  end

  describe '.validates' do
    it 'registra validações declarativas' do
      declarative_class = Class.new(described_class) do
        attributes :name
        validates :name, presence: true
      end

      expect(declarative_class.validations).to eq(
        [
          {
            attribute: :name,
            options: { presence: true }
          }
        ]
      )
    end

    it 'valida presença contra nil' do
      declarative_class = Class.new(described_class) do
        attributes :name
        validates :name, presence: true
      end

      expect {
        declarative_class.new(name: nil)
      }.to raise_error(ArgumentError, 'name cannot be nil or empty')
    end

    it 'valida presença contra string em branco' do
      declarative_class = Class.new(described_class) do
        attributes :name
        validates :name, presence: true
      end

      expect {
        declarative_class.new(name: '   ')
      }.to raise_error(ArgumentError, 'name cannot be nil or empty')
    end

    it 'valida presença contra array vazio' do
      declarative_class = Class.new(described_class) do
        attributes :items
        validates :items, presence: true
      end

      expect {
        declarative_class.new(items: [])
      }.to raise_error(ArgumentError, 'items cannot be nil or empty')
    end

    it 'permite mensagem customizada de presença' do
      declarative_class = Class.new(described_class) do
        attributes :user_id
        validates :user_id, presence: { message: 'user_id cannot be nil' }
      end

      expect {
        declarative_class.new(user_id: nil)
      }.to raise_error(ArgumentError, 'user_id cannot be nil')
    end

    it 'valida inclusão em coleção configurada' do
      declarative_class = Class.new(described_class) do
        VALID_STATUSES = %w[pending active].freeze

        attributes :status
        validates :status, inclusion: { in: VALID_STATUSES }
      end

      expect {
        declarative_class.new(status: 'blocked')
      }.to raise_error(ArgumentError, 'status must be one of: pending, active')
    end

    it 'permite valores incluídos na coleção' do
      declarative_class = Class.new(described_class) do
        attributes :status
        validates :status, inclusion: { in: %w[pending active] }
      end

      expect(declarative_class.new(status: 'active').status).to eq('active')
    end

    it 'ignora inclusão para valor nil quando presença não foi exigida' do
      declarative_class = Class.new(described_class) do
        attributes :document_type
        validates :document_type, inclusion: { in: %w[cpf cnpj mei] }
      end

      expect(declarative_class.new(document_type: nil).document_type).to be_nil
    end
  end

  describe '.sensitive_attributes' do
    it 'registra atributos sensíveis declarados' do
      declarative_class = Class.new(described_class) do
        attributes :email, :password_digest
        sensitive_attributes :email, :password_digest
      end

      expect(declarative_class.sensitive_attribute_names).to eq(%i[email password_digest])
    end

    it 'herda atributos sensíveis da classe pai' do
      parent_class = Class.new(described_class) do
        attributes :email
        sensitive_attributes :email
      end
      child_class = Class.new(parent_class) do
        attributes :document_number
        sensitive_attributes :document_number
      end

      expect(child_class.sensitive_attribute_names).to eq(%i[email document_number])
    end
  end

  describe '#to_h' do
    let(:privacy_class) do
      Class.new(described_class) do
        attributes :id, :email, :status
        sensitive_attributes :email
      end
    end

    it 'retorna atributos declarados sem redigir por padrão' do
      entity = privacy_class.new(id: 1, email: 'john@example.com', status: 'active')

      expect(entity.to_h).to eq(id: 1, email: 'john@example.com', status: 'active')
    end

    it 'redige atributos sensíveis quando solicitado' do
      entity = privacy_class.new(id: 1, email: 'john@example.com', status: 'active')

      expect(entity.to_h(redact: true)).to eq(id: 1, email: '[FILTERED]', status: 'active')
    end

    it 'não redige atributos sensíveis nulos' do
      entity = privacy_class.new(id: 1, email: nil, status: 'active')

      expect(entity.to_h(redact: true)).to eq(id: 1, email: nil, status: 'active')
    end
  end

  describe '#as_json' do
    it 'redige atributos sensíveis por padrão' do
      declarative_class = Class.new(described_class) do
        attributes :id, :email
        sensitive_attributes :email
      end

      expect(declarative_class.new(id: 1, email: 'john@example.com').as_json).to eq(
        id: 1,
        email: '[FILTERED]'
      )
    end
  end

  describe '#inspect' do
    it 'redige atributos sensíveis para evitar vazamento em logs' do
      declarative_class = Class.new(described_class) do
        attributes :id, :email
        sensitive_attributes :email
      end

      inspected = declarative_class.new(id: 1, email: 'john@example.com').inspect

      expect(inspected).to include('email: "[FILTERED]"')
      expect(inspected).not_to include('john@example.com')
    end
  end

  describe '#validate!' do
    it 'retorna a própria entidade quando válida' do
      declarative_class = Class.new(described_class) do
        attributes :name
        validates :name, presence: true
      end

      entity = declarative_class.new(name: 'John')

      expect(entity.validate!).to eq(entity)
    end
  end

  describe '#==' do
    context 'when entities have same class and all attributes equal' do
      it 'returns true' do
        expect(entity1).to eq(entity2)
      end
    end

    context 'when entities have different classes' do
      it 'returns false' do
        other_class = Class.new(described_class) do
          attr_reader :id
          def initialize(id:)
            super(id: id)
          end
        end
        other_entity = other_class.new(id: 1)

        expect(entity1).not_to eq(other_entity)
      end
    end

    context 'when entities have different attribute values' do
      it 'returns false for different id' do
        expect(entity1).not_to eq(entity3)
      end

      it 'returns false for different name' do
        expect(entity1).not_to eq(entity4)
      end
    end

    context 'when comparing with nil' do
      it 'returns false' do
        expect(entity1).not_to eq(nil)
      end
    end

    context 'when comparing with non-entity objects' do
      it 'returns false' do
        expect(entity1).not_to eq('string')
        expect(entity1).not_to eq(123)
        expect(entity1).not_to eq({})
      end
    end
  end

  describe '#eql?' do
    it 'behaves the same as ==' do
      expect(entity1.eql?(entity2)).to eq(entity1 == entity2)
      expect(entity1.eql?(entity3)).to eq(entity1 == entity3)
    end
  end

  describe '#hash' do
    context 'when entities are equal' do
      it 'returns the same hash value' do
        expect(entity1.hash).to eq(entity2.hash)
      end
    end

    context 'when entities are not equal' do
      it 'returns different hash values' do
        expect(entity1.hash).not_to eq(entity3.hash)
        expect(entity1.hash).not_to eq(entity4.hash)
      end
    end

    it 'includes class and all instance variables in hash calculation' do
      expected_hash = [ entity_class, 1, 'John', 'john@example.com' ].hash
      expect(entity1.hash).to eq(expected_hash)
    end

    it 'is consistent for the same entity' do
      hash1 = entity1.hash
      hash2 = entity1.hash
      expect(hash1).to eq(hash2)
    end
  end

  describe 'usage in collections' do
    it 'works correctly with Set' do
      set = Set.new([ entity1, entity2, entity3 ])
      expect(set.size).to eq(2) # entity1 and entity2 are equal
      expect(set).to include(entity1)
      expect(set).to include(entity3)
    end

    it 'works correctly with Hash keys' do
      hash = {}
      hash[entity1] = 'value1'
      hash[entity2] = 'value2' # Should overwrite entity1

      expect(hash.size).to eq(1)
      expect(hash[entity1]).to eq('value2')
      expect(hash[entity2]).to eq('value2')
    end
  end

  describe 'inheritance' do
    let(:child_class) do
      Class.new(entity_class) do
        attr_reader :age

        def initialize(id:, name:, email:, age:)
          super(id: id, name: name, email: email)
          @age = age
        end
      end
    end

    let(:parent_entity) { entity_class.new(id: 1, name: 'John', email: 'john@example.com') }
    let(:child_entity) { child_class.new(id: 1, name: 'John', email: 'john@example.com', age: 30) }

    it 'treats parent and child classes as different' do
      expect(parent_entity).not_to eq(child_entity)
    end

    it 'child entities compare correctly with each other' do
      child_entity2 = child_class.new(id: 1, name: 'John', email: 'john@example.com', age: 30)
      expect(child_entity).to eq(child_entity2)
    end
  end
end
