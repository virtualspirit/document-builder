module Document
  module Grape
    module Presenters
      class Section < Base
        expose :id
        expose :title
        expose :description
        expose :headless
        expose :form_id
        expose :position
        expose :fields, with: Field
        expose :created_at
        expose :updated_at
      end
    end
  end
end