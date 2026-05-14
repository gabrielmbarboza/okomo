# frozen_string_literal: true

module DomainValueObject
  class DomainValueObjectGenerator < Rails::Generators::NamedBase
    source_root File.expand_path('templates', __dir__)

    argument :domain, type: :string, required: true, banner: 'DOMAIN'

    def create_value_object_file
      template 'value_object.rb.tt', File.join('app/domains', domain.underscore, 'value_objects', "#{file_name}.rb")
    end
  end
end
