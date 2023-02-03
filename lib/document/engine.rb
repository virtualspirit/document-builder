begin; require 'grape'; rescue LoadError; end
begin; require 'cancancan'; rescue LoadError; end

module Document
  class Engine < ::Rails::Engine
    isolate_namespace Document

    config.after_initialize do
      klass = Document::Grape::Services::Base
      if defined?(Cancan)
        require 'document/grape/cancan'
        require 'document/grape/ability'
        klass.send(:include, Document::Grape::Cancan)
      end
      if defined?(GrapeAPI::Resourceful::Resource)
        require 'document/grape/resource'
        klass.include Document::Grape::Resource
      end
    end

    initializer "document.form_helpers" do
      ActiveSupport.on_load(:action_view) { require 'document/rails/form_helpers' }
    end

  end
end
