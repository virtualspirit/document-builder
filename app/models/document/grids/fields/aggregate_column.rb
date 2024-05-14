module Document
  module Grids
    module Fields
      class AggregateColumn < ::Document::Grids::Field

        before_save do
          self.default_aggregation = false
        end

        def set_as_default
          # update(default: true)
        end

        class << self

          def created_at
            ca = where(default: true, name: "created_at").first
            unless ca
              ca = self.new(name: "created_at", label: "Created at", default: true)
              ca.aggregation.stages.build(name: "$project", order: 9999, arguments_attributes: [{function: "#{ca.name}", parameter: 1}])
              ca.save
            end
            ca
          end

          def updated_at
            ua = where(default: true, name: "updated_at").first
            unless ua
              ua = self.new(name: "updated_at", label: "Updated at", default: true)
              ua.aggregation.stages.build(name: "$project", order: 9999, arguments_attributes: [{function: "#{ua.name}", parameter: 1}])
              ua.save
            end
            ua
          end

        end

      end
    end
  end
end