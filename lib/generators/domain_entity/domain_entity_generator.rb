# frozen_string_literal: true

module DomainEntity
  class DomainEntityGenerator < Rails::Generators::NamedBase
    source_root File.expand_path('templates', __dir__)

    argument :domain, type: :string, required: true, banner: 'DOMAIN'

    def create_entity_file
      template 'entity.rb.tt', File.join('app/domains', domain.underscore, 'entities', "#{file_name}.rb")
    end
  end
end
