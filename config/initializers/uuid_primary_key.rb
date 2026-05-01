# frozen_string_literal: true

# Configure UUID as primary key by default for all models
Rails.application.configure do
  config.generators do |g|
    g.orm :active_record, primary_key_type: :uuid
  end
end

# Enable pgcrypto extension for UUID generation
class EnablePgcryptoExtension < ActiveRecord::Migration[7.0]
  def change
    enable_extension 'pgcrypto'
  end
end
