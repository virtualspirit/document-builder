begin; require 'grape'; rescue LoadError; end
begin; require 'cancancan'; rescue LoadError; end

if defined?(Grape::API) and defined?(CanCanCan)

  klass = if Grape::VERSION >= '1.2.0' || defined?(Grape::API::Instance)
    Grape::API::Instance
  else
    Grape::API
  end
  klass = Document::Grape::Services::Base
  require 'document/grape/cancan'
  require 'document/grape/ability'
  klass.send(:include, Document::Grape::Cancan)

  if defined?(GrapeAPI::Resourceful::Resource)
    require 'document/grape/resource'
    klass.include Document::Grape::Resource
  end


end
