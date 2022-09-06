module Document
  module Grape
    module Presenters
      class VirtualField < Base
        expose :id
        expose :name
        expose :label
        expose :hint
        expose :accessibility
        expose :options
        expose :validations
        expose :value
        expose :value_for_preview
        expose :type
        expose :position
        expose :nested_form do |resource|
          if resource.nested_form
            if resource.value_for_preview
              if resource.multiple_nested_form?
                res = resource.nested_form.virtual_fields.map do |vps|
                  self.class.represent vps, root: false
                end
                res
              else
                self.class.represent resource.nested_form.virtual_fields, root: false
              end
            else
              Field.represent resource.nested_form.fields, root: false
            end
          end
        end
      end
    end
  end
end