module Document
  module Generators
    class ConfigGenerator < Rails::Generators::Base
      source_root File.join(__dir__, "templates")

      def generate_config
        copy_file "document.rb", "config/initializers/document.rb"
      end
    end
  end
end