# frozen_string_literal: true

# Load all service files in the catalog domain
Dir[File.join(__dir__, 'services', '*.rb')].each { |file| require file }
