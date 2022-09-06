module Document
  module Grape
    module Presenters
      class Field < Base
        expose :id
        expose :name
        expose :label
        expose :hint
        expose :accessibility
        expose :options do |instance|
          if instance.attached_nested_form?
            Document::Grape::Presenters::Fields::Option.represent(instance.options, root: false)
          else
            unless !instance.is_a?(Document::NonConfigurableField)
              "Document::Grape::Presenters::Fields::Options::#{instance.type.demodulize}".constantize.represent(instance.options, root: false)
            end
          end
        end
        expose :validations, with: Document::Grape::Presenters::Fields::Validations
        expose :nested_form, with: Document::Grape::Presenters::NestedForm, if: lambda {|instance| instance.nested_form }
        expose :type
        expose :section_id
        expose :form_id
        expose :data_type
        expose :position
        expose :created_at
        expose :updated_at

      end
    end
  end
end