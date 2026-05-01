# frozen_string_literal: true

# Load all entity files in the catalog domain
Dir[File.join(__dir__, 'entities', '*.rb')].each { |file| require file }
