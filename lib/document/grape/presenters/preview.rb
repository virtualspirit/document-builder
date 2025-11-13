module Document
  module Grape
    module Presenters
      class Preview < Base

        expose :id
        expose :name
        expose :title
        expose :code
        expose :step
        expose :step_options
        expose :created_at
        expose :updated_at
        expose :sections do |object, options|
          Document::Grape::Presenters::Preview::Section.represent(object.sections, options)
        end

        class Section < Document::Grape::Presenters::Base

          expose :id
          expose :title
          expose :description
          expose :headless
          expose :form_id
          expose :position
          expose :fields do |object, options|
            Document::Grape::Presenters::VirtualField.represent(object.virtual_fields(options[:instance]))
          end
          expose :created_at
          expose :updated_at

        end

      end

    end
  end
end