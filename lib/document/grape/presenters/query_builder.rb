module Document
  module Grape
    module Presenters
      class QueryBuilder < Base
        expose :id
        expose :name
        expose :context
        expose :form_id
        expose :clauses do |object|
         object.data.clauses
        end
        expose :created_at
        expose :updated_at
      end
    end
  end
end