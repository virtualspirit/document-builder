begin; require 'grape'; rescue LoadError; end
begin; require 'cancancan'; rescue LoadError; end

module Document
  class Engine < ::Rails::Engine
    isolate_namespace Document

    config.after_initialize do
      klass = Document::Grape::Services::Base
      require 'document/grape/cancan'
      require 'document/grape/ability'
      klass.send(:include, Document::Grape::Cancan)
      if defined?(GrapeAPI::Resourceful::Resource)
        require 'document/grape/resource'
        klass.include Document::Grape::Resource
      end
    end

  end
end
