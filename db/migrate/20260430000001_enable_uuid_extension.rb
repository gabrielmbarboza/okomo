# frozen_string_literal: true

# Enable UUID support for PostgreSQL.
# This migration enables the pgcrypto extension which provides gen_random_uuid().
class EnableUuidExtension < ActiveRecord::Migration[8.1]
  def change
    enable_extension "pgcrypto"
  end
end
