# frozen_string_literal: true

module DomainEntity
  class DomainEntityGenerator < Rails::Generators::Base
    source_root File.expand_path('templates', __dir__)

    argument :domain, type: :string, required: true, banner: 'DOMAIN'
    argument :entity, type: :string, required: true, banner: 'ENTITY'

    def create_entity_file
      template 'entity.rb.tt', File.join('app/domains', domain.underscore, 'entities', "#{entity.underscore}.rb")
    end

    private

    def class_name
      entity.camelize
    end

    def module_name
      domain.camelize
    end
  end
end
