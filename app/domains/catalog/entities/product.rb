# frozen_string_literal: true

require "securerandom"

module Catalog
  module Entities
    # Product representa um produto conceitual cadastrado por um seller.
    # Agrupa uma ou mais Variant, mas não define preço nem estoque
    # diretamente (ADR-007) — isso pertence exclusivamente à Variant.
    #
    # Atributos:
    # - id: UUID único
    # - seller_profile_id: UUID do SellerProfile dono do produto
    # - name: Nome do produto
    # - description: Descrição opcional do produto
    # - status: draft, published, archived
    # - created_at, updated_at: Timestamps
    class Product < Shared::Entities::BaseEntity
      DRAFT = "draft"
      PUBLISHED = "published"
      ARCHIVED = "archived"

      VALID_STATUSES = [ DRAFT, PUBLISHED, ARCHIVED ].freeze

      attribute :id, default: -> { SecureRandom.uuid }
      attributes :seller_profile_id, :name, :description
      attribute :status, default: DRAFT
      attribute :created_at, default: -> { Time.current }
      attribute :updated_at, default: ->(product) { product.created_at }

      validates :id, presence: { message: "id cannot be nil" }
      validates :seller_profile_id, presence: true
      validates :name, presence: true
      validates :status, inclusion: { in: VALID_STATUSES }

      # Verifica se Product está em rascunho
      def draft?
        @status == DRAFT
      end

      # Verifica se Product foi publicado
      def published?
        @status == PUBLISHED
      end

      # Verifica se Product foi arquivado
      def archived?
        @status == ARCHIVED
      end

      def publish!(published_at: Time.current)
        raise ArgumentError, "product must be draft to be published" unless draft?
        raise ArgumentError, "product must have a description to be published" if description.blank?

        @status = PUBLISHED
        @updated_at = published_at

        self
      end
    end
  end
end
