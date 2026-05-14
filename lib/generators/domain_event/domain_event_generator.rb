# frozen_string_literal: true

module DomainEvent
  class DomainEventGenerator < Rails::Generators::NamedBase
    source_root File.expand_path('templates', __dir__)

    argument :domain, type: :string, required: true, banner: 'DOMAIN'

    def create_event_file
      template 'event.rb.tt', File.join('app/domains', domain.underscore, 'events', "#{file_name}.rb")
    end
  end
end
