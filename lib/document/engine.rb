require 'grape'
module Document
  class Engine < ::Rails::Engine
    isolate_namespace Document

    config.after_initialize do
    begin; require 'cancancan'; rescue LoadError; end
    
    if defined?(CanCan) and defined?(Grape::API)
      
      begin; require 'document/grape/services/base'; rescue LoadError; end 

      if defined?(Document::Grape::Services::Base)
        klass = Document::Grape::Services::Base
        
        begin; require 'document/grape/cancan'; rescue LoadError; end
        begin; require 'document/grape/ability'; rescue LoadError; end
        
        if defined?(Document::Grape::Cancan)
          klass.include Document::Grape::Cancan
        end
        
        begin; require 'document/grape/resource'; rescue LoadError; end
        
        if defined?(Document::Grape::Resource)
          klass.include Document::Grape::Resource
        end
      end
    end
  end

    initializer "document.form_helpers" do
      ActiveSupport.on_load(:action_view) { require 'document/rails/form_helpers' }
    end

  end
end
