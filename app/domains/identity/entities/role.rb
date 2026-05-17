# frozen_string_literal: true

require "securerandom"

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

      attribute :id, default: -> { SecureRandom.uuid }
      attributes :name, :description
      attribute :created_at, default: -> { Time.current }
      attribute :updated_at, default: ->(role) { role.created_at }

      validates :id, presence: { message: "id cannot be nil" }
      validates :name, presence: true
      validates :name, inclusion: { in: VALID_NAMES }

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
