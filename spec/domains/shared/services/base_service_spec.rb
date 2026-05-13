# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Shared::Services::BaseService do
  let(:service_class) do
    Class.new(described_class) do
      attr_reader :params_called

      def initialize(param1, param2: nil)
        @param1 = param1
        @param2 = param2
        @params_called = false
      end

      def call
        @params_called = true
        "result: #{@param1}, #{@param2}"
      end
    end
  end

  let(:concrete_service_class) do
    Class.new(described_class) do
      def call
        'concrete result'
      end
    end
  end

  describe '.call' do
    context 'when called with positional arguments' do
      it 'creates instance and delegates to #call' do
        result = service_class.call('test_value')
        expect(result).to eq('result: test_value, ')
      end
    end

    context 'when called with keyword arguments' do
      it 'creates instance and delegates to #call' do
        result = service_class.call('test_value', param2: 'keyword_value')
        expect(result).to eq('result: test_value, keyword_value')
      end
    end

    context 'when called with mixed arguments' do
      it 'creates instance and delegates to #call' do
        result = service_class.call('test_value', param2: 'keyword_value')
        expect(result).to eq('result: test_value, keyword_value')
      end
    end

    context 'when called with no arguments' do
      let(:no_args_service) do
        Class.new(described_class) do
          def call
            'no args result'
          end
        end
      end

      it 'creates instance and delegates to #call' do
        result = no_args_service.call
        expect(result).to eq('no args result')
      end
    end

    it 'passes all arguments to constructor' do
      result = service_class.call('arg1', param2: 'arg2')
      expect(result).to eq('result: arg1, arg2')
    end

    it 'returns the result of instance #call method' do
      result = concrete_service_class.call
      expect(result).to eq('concrete result')
    end
  end

  describe '#call' do
    context 'when using base service directly' do
      it 'raises NotImplementedError' do
        base_service = described_class.new
        expect { base_service.call }.to raise_error(NotImplementedError, 'Subclasses must implement this method')
      end
    end

    context 'when using subclass with implementation' do
      it 'returns the implementation result' do
        service = concrete_service_class.new
        result = service.call
        expect(result).to eq('concrete result')
      end
    end

    context 'when subclass has access to instance variables' do
      it 'can access constructor parameters' do
        service = service_class.new('test', param2: 'value')
        result = service.call
        expect(result).to eq('result: test, value')
        expect(service.params_called).to be true
      end
    end
  end

  describe 'inheritance and polymorphism' do
    let(:parent_service) do
      Class.new(described_class) do
        def call
          'parent result'
        end
      end
    end

    let(:child_service) do
      Class.new(parent_service) do
        def call
          'child result'
        end
      end
    end

    it 'maintains inheritance chain' do
      expect(parent_service.new.call).to eq('parent result')
      expect(child_service.new.call).to eq('child result')
    end

    it 'class method works through inheritance' do
      expect(parent_service.call).to eq('parent result')
      expect(child_service.call).to eq('child result')
    end
  end

  describe 'error handling' do
    let(:error_service) do
      Class.new(described_class) do
        def call
          raise StandardError, 'service error'
        end
      end
    end

    it 'propagates errors from instance #call method' do
      expect { error_service.call }.to raise_error(StandardError, 'service error')
    end

    it 'propagates errors from constructor' do
      constructor_error_service = Class.new(described_class) do
        def initialize
          raise ArgumentError, 'invalid params'
        end
      end

      expect { constructor_error_service.call }.to raise_error(ArgumentError, 'invalid params')
    end
  end

  describe 'method signature compatibility' do
    context 'with different argument types' do
      let(:var_args_service) do
        Class.new(described_class) do
          def initialize(*args)
            @args = args
          end

          def call
            "args: #{@args.join(', ')}"
          end
        end
      end

      it 'handles variable arguments' do
        result = var_args_service.call('a', 'b', 'c')
        expect(result).to eq('args: a, b, c')
      end
    end

    context 'with keyword splat arguments' do
      let(:kw_args_service) do
        Class.new(described_class) do
          def initialize(**kwargs)
            @kwargs = kwargs
          end

          def call
            "kwargs: #{@kwargs}"
          end
        end
      end

      it 'handles keyword arguments' do
        result = kw_args_service.call(a: 1, b: 2, c: 3)
        expect(result).to eq('kwargs: {:a=>1, :b=>2, :c=>3}')
      end
    end
  end

  describe 'instance state' do
    let(:stateful_service) do
      Class.new(described_class) do
        attr_reader :call_count

        def initialize
          @call_count = 0
        end

        def call
          @call_count += 1
          "call ##{@call_count}"
        end
      end
    end

    it 'maintains separate instance state' do
      service1 = stateful_service.new
      service2 = stateful_service.new

      expect(service1.call).to eq('call #1')
      expect(service2.call).to eq('call #1')
      expect(service1.call).to eq('call #2')
      expect(service2.call).to eq('call #2')
    end

    it 'class method creates new instance each time' do
      expect(stateful_service.call).to eq('call #1')
      expect(stateful_service.call).to eq('call #1') # New instance
    end
  end
end
