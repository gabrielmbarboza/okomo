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
      expected_hash = [entity_class, 1, 'John', 'john@example.com'].hash
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
      set = Set.new([entity1, entity2, entity3])
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
