# frozen_string_literal: true

module Domain
  class DomainGenerator < Rails::Generators::NamedBase
    source_root File.expand_path('templates', __dir__)

    def create_domain_structure
      create_domain_module
      create_subdirectories
    end

    private

    def create_domain_module
      template 'domain.rb.tt', File.join('app/domains', file_name, "#{file_name}.rb")
    end

    def create_subdirectories
      %w[entities services repositories value_objects events specifications policies].each do |dir|
        empty_directory File.join('app/domains', file_name, dir)
      end
    end
  end
end
