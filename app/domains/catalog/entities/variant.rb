# frozen_string_literal: true

require "securerandom"

module Catalog
  module Entities
    # Variant é a unidade vendável do catálogo. Por decisão da ADR-007,
    # preço e estoque pertencem exclusivamente à Variant, nunca ao Product.
    #
    # Atributos:
    # - id: UUID único
    # - product_id: UUID do Product pai
    # - name: Nome da variante
    # - sku: Identificador único dentro do escopo do produto (BR-CAT-010)
    # - price: Preço da variante, deve ser maior que zero (BR-CAT-011)
    # - weight_grams, height_cm, width_cm, length_cm: Dimensões opcionais,
    #   quando informadas devem ser positivas (BR-CAT-012)
    # - status: draft, published, archived
    # - created_at, updated_at: Timestamps
    class Variant < Shared::Entities::BaseEntity
      DRAFT = "draft"
      PUBLISHED = "published"
      ARCHIVED = "archived"

      VALID_STATUSES = [ DRAFT, PUBLISHED, ARCHIVED ].freeze

      POSITIVE_WHEN_PRESENT_ATTRIBUTES = %i[weight_grams height_cm width_cm length_cm].freeze

      attribute :id, default: -> { SecureRandom.uuid }
      attributes :product_id, :name, :sku, :price, *POSITIVE_WHEN_PRESENT_ATTRIBUTES
      attribute :status, default: DRAFT
      attribute :created_at, default: -> { Time.current }
      attribute :updated_at, default: ->(variant) { variant.created_at }

      validates :id, presence: { message: "id cannot be nil" }
      validates :product_id, presence: true
      validates :name, presence: true
      validates :sku, presence: true
      validates :status, inclusion: { in: VALID_STATUSES }

      def validate!
        super

        raise ArgumentError, "price must be greater than zero" if price.nil? || price <= 0

        POSITIVE_WHEN_PRESENT_ATTRIBUTES.each do |attribute_name|
          value = public_send(attribute_name)
          next if value.nil?

          raise ArgumentError, "#{attribute_name} must be positive" if value <= 0
        end
      end

      # Verifica se Variant está em rascunho
      def draft?
        @status == DRAFT
      end

      # Verifica se Variant foi publicada
      def published?
        @status == PUBLISHED
      end

      # Verifica se Variant foi arquivada
      def archived?
        @status == ARCHIVED
      end

      # Verifica se Variant pode ser vendida (qualquer status exceto archived)
      def sellable?
        !archived?
      end
    end
  end
end
