# frozen_string_literal: true

module DomainRepository
  class DomainRepositoryGenerator < Rails::Generators::NamedBase
    source_root File.expand_path('templates', __dir__)

    argument :domain, type: :string, required: true, banner: 'DOMAIN'

    def create_repository_file
      template 'repository.rb.tt', File.join('app/domains', domain.underscore, 'repositories', "#{file_name}.rb")
    end
  end
end
