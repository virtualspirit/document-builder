require 'rails/generators/active_record'
require 'active_support/core_ext'
require 'erb'

module Document
  module Generators
    class IsDocumentGenerator < Rails::Generators::Base

      include ActiveRecord::Generators::Migration
      source_root File.join(__dir__, "templates")

      argument :is_document_cname, :type => :string, :default => "Document", :banner => "Document"

      def ensure_is_document_class_defined
        unless is_document_class_defined?
          prompt_missing_is_document
          abort
        end
      end

      def copy_migration
        migration_template "migration.rb", "db/migrate/add_fields_to_#{table_name}.rb", migration_version: migration_version
        inject_into_class(model_path, is_document_class, model_content)
      end

      def migration_version
        "[#{ActiveRecord::VERSION::MAJOR}.#{ActiveRecord::VERSION::MINOR}]"
      end


      private

        def model_path
          File.join("app", "models", "#{is_document_cname.underscore}.rb")
        end

        def model_content
          ERB.new(File.read(File.join(__dir__, 'templates/model.rb'))).result(binding)
        end

        def is_document_class
          is_document_cname.constantize
        end

        def table_name
          is_document_class.table_name
        end

        def is_document_class_defined?
          is_document_class
          true
        rescue NameError => ex
          if ex.missing_name == is_document_cname
            false
          else
            raise ex
          end
        end

    end
  end
end