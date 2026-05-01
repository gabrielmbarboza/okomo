# frozen_string_literal: true

class ApplicationRecord < ActiveRecord::Base
  primary_abstract_class

  # All models inherit UUID as primary key by default.
  # New tables should be created with `id: :uuid` in migrations.
  #
  # Example migration:
  #   create_table :products, id: :uuid do |t|
  #     t.string :name, null: false
  #     t.timestamps
  #   end
  #
  # ActiveRecord models should remain thin — data access only.
  # Business logic belongs in app/domains/<domain>/services/ or entities/.
end
