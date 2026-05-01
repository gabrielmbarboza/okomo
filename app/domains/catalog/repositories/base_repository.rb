# frozen_string_literal: true

module Catalog
  module Repositories
    # Base class for Catalog domain repositories.
    #
    # Repositories abstract data access and persistence.
    # They translate between domain entities and ActiveRecord models.
    #
    # Usage:
    #   class Catalog::Repositories::ProductRepository < Catalog::Repositories::BaseRepository
    #     def find(id)
    #       record = Product.find(id)
    #       Catalog::Entities::Product.new(
    #         id: record.id,
    #         name: record.name
    #       )
    #     end
    #   end
    #
    class BaseRepository
    end
  end
end
