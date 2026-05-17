# frozen_string_literal: true

module Identity
  module Entities
    # Role representa um catálogo global de permissões da plataforma.
    #
    # Exemplos:
    # - buyer: Permissão para realizar compras
    # - seller: Permissão para vender produtos
    # - platform_admin: Permissão para administrar a plataforma
    #
    # Roles são estáticas e não mudam frequentemente. Elas funcionam como um
    # catálogo de referência para sistemas de autorização.
    class Role < Shared::Entities::BaseEntity
      BUYER = 'buyer'
      SELLER = 'seller'
      PLATFORM_ADMIN = 'platform_admin'

      VALID_NAMES = [BUYER, SELLER, PLATFORM_ADMIN].freeze

      attr_accessor :id,
                    :name,
                    :description,
                    :created_at,
                    :updated_at

      def initialize(id:, name:, description: nil, created_at: nil, updated_at: nil)
        @id = id
        @name = name
        @description = description
        @created_at = created_at || Time.current
        @updated_at = updated_at || @created_at

        validate!
      end

      def validate!
        raise ArgumentError, "id cannot be nil" if @id.nil?
        raise ArgumentError, "name cannot be nil or empty" if @name.blank?
        raise ArgumentError, "name must be one of: #{VALID_NAMES.join(', ')}" unless VALID_NAMES.include?(@name)
      end

      def buyer?
        @name == BUYER
      end

      def seller?
        @name == SELLER
      end

      def admin?
        @name == PLATFORM_ADMIN
      end
    end
  end
end
