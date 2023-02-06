require "rails/generators/active_record"
require "active_record"

module Document
  module Generators
    class InstallGenerator < ::Rails::Generators::Base
      include ActiveRecord::Generators::Migration
      source_root File.join(__dir__, "templates")

      def copy_migration
        unless ActiveRecord::Base.connection.table_exists? 'support_uploads'
          invoke "support:uploadable:install"
        end
        migration_template "migration.rb", "db/migrate/create_document_tables.rb", migration_version: migration_version
      end

      def migration_version
        "[#{ActiveRecord::VERSION::MAJOR}.#{ActiveRecord::VERSION::MINOR}]"
      end
    end
  end
end