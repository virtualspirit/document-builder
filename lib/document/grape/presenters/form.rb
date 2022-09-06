module Document
  module Grape
    module Presenters
      class Form < Base
        expose :id
        expose :name
        expose :title
        expose :code
        expose :sections, with: Document::Grape::Presenters::Section
        expose :step
        expose :step_options
        expose :created_at
        expose :updated_at
      end
    end
  end
end