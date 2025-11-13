module Document
  module Grids
    module Fields
      class NestedColumn < ::Document::Grids::Field

        include Concerns::Default
        include Concerns::Nested

        self.valid_field_types = ['Document::Fields::NestedFormField', 'Document::Fields::DepedencyOneField']

        def to_virtual_view
          if field && field.depedency_field?
            @virtual_view ||= field.options.form.to_virtual_view
          end
        end

        def build_default_aggregation(grid_container=nil)
          if default_aggregation
            if name
              super
              if depedency_field?
                aggregation.stages.build(name: "$project", order: 9999, arguments_attributes: [{function: "#{name}_id", parameter: 1}])
              end
            end
          end
        end

      end
    end
  end
end