module Document
  class Engine < ::Rails::Engine
    isolate_namespace Document

    config.after_initialize do
      begin
        require 'cancancan';
        klass = Document::Grape::Services::Base
        require 'document/grape/cancan'
        require 'document/grape/ability'
        klass.include Document::Grape::Cancan
        require 'document/grape/resource'
        klass.include Document::Grape::Resource
      rescue LoadError; end
      begin
      end
    end

    initializer "document.form_helpers" do
      ActiveSupport.on_load(:action_view) { require 'document/rails/form_helpers' }
    end

  end
end
