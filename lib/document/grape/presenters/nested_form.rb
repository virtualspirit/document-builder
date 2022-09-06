module Document
  module Grape
    module Presenters
      class NestedForm < Base
        expose :id
        expose :fields, with: Document::Grape::Presenters::Field
        expose :created_at
        expose :updated_at
      end
    end
  end
end