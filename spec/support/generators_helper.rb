# frozen_string_literal: true

# Helper module for testing Rails generators
module GeneratorsHelper
  # Execute a generator with the given arguments
  # @param generator_class [Class] The generator class to run
  # @param args [Array<String>] Arguments to pass to the generator
  # @param options [Hash] Options for the generator
  # @return [Rails::Generators::Base] The generator instance
  def run_generator(generator_class, args = [], options = {})
    destination_root = Dir.mktmpdir
    generator = generator_class.new(args, options, destination_root: destination_root)
    generator.invoke_all
    generator
  end

  # Read the contents of a generated file
  # @param generator [Rails::Generators::Base] The generator instance
  # @param path [String] Relative path to the file
  # @return [String, nil] File contents or nil if file doesn't exist
  def read_generated_file(generator, path)
    file_path = File.join(generator.destination_root, path)
    File.exist?(file_path) ? File.read(file_path) : nil
  end

  # Check if a file was generated
  # @param generator [Rails::Generators::Base] The generator instance
  # @param path [String] Relative path to the file
  # @return [Boolean] True if file exists
  def file_exists?(generator, path)
    file_path = File.join(generator.destination_root, path)
    File.exist?(file_path)
  end

  # Check if a directory was generated
  # @param generator [Rails::Generators::Base] The generator instance
  # @param path [String] Relative path to the directory
  # @return [Boolean] True if directory exists
  def directory_exists?(generator, path)
    dir_path = File.join(generator.destination_root, path)
    Dir.exist?(dir_path)
  end

  # Cleanup temporary files after test
  # @param generator [Rails::Generators::Base] The generator instance
  def cleanup_generator(generator)
    FileUtils.rm_rf(generator.destination_root) if generator&.destination_root
  end
end
