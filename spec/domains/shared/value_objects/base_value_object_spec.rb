# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Shared::ValueObjects::BaseValueObject do
  let(:value_object_class) do
    Class.new(described_class) do
      attr_reader :amount, :currency
      
      def initialize(amount: nil, currency: nil)
        super(amount: amount, currency: currency)
      end
    end
  end

  let(:vo1) { value_object_class.new(amount: 100, currency: 'USD') }
  let(:vo2) { value_object_class.new(amount: 100, currency: 'USD') }
  let(:vo3) { value_object_class.new(amount: 200, currency: 'USD') }
  let(:vo4) { value_object_class.new(amount: 100, currency: 'EUR') }

  describe '#initialize' do
    it 'sets instance variables from attributes' do
      expect(vo1.amount).to eq(100)
      expect(vo1.currency).to eq('USD')
    end

    it 'freezes the object after initialization' do
      expect(vo1).to be_frozen
    end

    it 'handles empty attributes' do
      empty_vo = value_object_class.new
      expect(empty_vo.amount).to be_nil
      expect(empty_vo.currency).to be_nil
      expect(empty_vo).to be_frozen
    end
  end

  describe 'immutability' do
    it 'prevents modification of attributes' do
      # Since we only have attr_reader, there are no setter methods
      # The object is frozen, so any attempt to modify it will fail
      expect(vo1).to be_frozen
      
      # Test that we can't add new instance variables
      expect { vo1.instance_variable_set(:@new_var, 'value') }.to raise_error(FrozenError)
    end

    it 'prevents adding new instance variables' do
      expect { vo1.instance_variable_set(:@new_var, 'value') }.to raise_error(FrozenError)
    end

    it 'prevents modification of collections' do
      mutable_class = Class.new(described_class) do
        attr_reader :items
        
        def initialize(items:)
          super(items: items.freeze)
        end
      end
      
      mutable_vo = mutable_class.new(items: [1, 2, 3])
      expect { mutable_vo.items << 4 }.to raise_error(FrozenError)
      expect { mutable_vo.items[0] = 99 }.to raise_error(FrozenError)
    end
  end

  describe '#==' do
    context 'when value objects have same class and all attributes equal' do
      it 'returns true' do
        expect(vo1).to eq(vo2)
      end
    end

    context 'when value objects have different classes' do
      it 'returns false' do
        other_class = Class.new(described_class) do
          attr_reader :amount
          def initialize(amount:)
            super(amount: amount)
          end
        end
        other_vo = other_class.new(amount: 100)
        
        expect(vo1).not_to eq(other_vo)
      end
    end

    context 'when value objects have different attribute values' do
      it 'returns false for different amount' do
        expect(vo1).not_to eq(vo3)
      end

      it 'returns false for different currency' do
        expect(vo1).not_to eq(vo4)
      end
    end

    context 'when comparing with nil' do
      it 'returns false' do
        expect(vo1).not_to eq(nil)
      end
    end

    context 'when comparing with non-value objects' do
      it 'returns false' do
        expect(vo1).not_to eq('string')
        expect(vo1).not_to eq(100)
        expect(vo1).not_to eq({ amount: 100, currency: 'USD' })
      end
    end
  end

  describe '#eql?' do
    it 'behaves the same as ==' do
      expect(vo1.eql?(vo2)).to eq(vo1 == vo2)
      expect(vo1.eql?(vo3)).to eq(vo1 == vo3)
    end
  end

  describe '#hash' do
    context 'when value objects are equal' do
      it 'returns the same hash value' do
        expect(vo1.hash).to eq(vo2.hash)
      end
    end

    context 'when value objects are not equal' do
      it 'returns different hash values' do
        expect(vo1.hash).not_to eq(vo3.hash)
        expect(vo1.hash).not_to eq(vo4.hash)
      end
    end

    it 'includes class and all instance variables in hash calculation' do
      expected_hash = [value_object_class, 100, 'USD'].hash
      expect(vo1.hash).to eq(expected_hash)
    end

    it 'is consistent for the same value object' do
      hash1 = vo1.hash
      hash2 = vo1.hash
      expect(hash1).to eq(hash2)
    end
  end

  describe 'usage in collections' do
    it 'works correctly with Set' do
      set = Set.new([vo1, vo2, vo3])
      expect(set.size).to eq(2)
      expect(set).to include(vo1)
      expect(set).to include(vo3)
    end

    it 'works correctly with Hash keys' do
      hash = {}
      hash[vo1] = 'value1'
      hash[vo2] = 'value2'
      
      expect(hash.size).to eq(1)
      expect(hash[vo1]).to eq('value2')
      expect(hash[vo2]).to eq('value2')
    end
  end

  describe 'inheritance' do
    let(:child_class) do
      Class.new(described_class) do
        attr_reader :amount, :currency, :precision
        
        def initialize(amount: nil, currency: nil, precision: nil)
          @precision = precision
          super(amount: amount, currency: currency)
        end
      end
    end

    let(:parent_vo) { value_object_class.new(amount: 100, currency: 'USD') }
    let(:child_vo) { child_class.new(amount: 100, currency: 'USD', precision: 2) }

    it 'treats parent and child classes as different' do
      expect(parent_vo).not_to eq(child_vo)
    end

    it 'child value objects compare correctly with each other' do
      child_vo2 = child_class.new(amount: 100, currency: 'USD', precision: 2)
      expect(child_vo).to eq(child_vo2)
    end

    it 'child value objects are also frozen' do
      expect(child_vo).to be_frozen
    end
  end

  describe 'complex attributes' do
    let(:complex_class) do
      Class.new(described_class) do
        attr_reader :coordinates, :metadata
        
        def initialize(coordinates: nil, metadata: nil)
          super(coordinates: coordinates&.freeze, metadata: metadata&.freeze)
        end
      end
    end

    let(:coordinates) { [10.5, 20.3] }
    let(:metadata) { { type: 'location', verified: true } }
    let(:complex_vo) { complex_class.new(coordinates: coordinates, metadata: metadata) }

    it 'handles complex objects in attributes' do
      expect(complex_vo.coordinates).to eq(coordinates)
      expect(complex_vo.metadata).to eq(metadata)
    end

    it 'compares correctly with complex attributes' do
      same_vo = complex_class.new(coordinates: coordinates.dup, metadata: metadata.dup)
      expect(complex_vo).to eq(same_vo)
    end

    it 'prevents modification of nested mutable objects' do
      expect { complex_vo.coordinates << 30 }.to raise_error(FrozenError)
      expect { complex_vo.metadata[:new_key] = 'value' }.to raise_error(FrozenError)
    end
  end

  describe 'nil attributes' do
    let(:nil_vo) { value_object_class.new(amount: nil, currency: 'BRL') }
    let(:nil_vo2) { value_object_class.new(amount: nil, currency: 'BRL') }

    it 'handles nil attributes correctly' do
      expect(nil_vo.amount).to be_nil
      expect(nil_vo.currency).to eq('BRL')
    end

    it 'compares correctly with nil attributes' do
      expect(nil_vo).to eq(nil_vo2)
    end

    it 'does not equal when only one attribute is nil' do
      expect(nil_vo).not_to eq(vo1)
    end
  end
end
