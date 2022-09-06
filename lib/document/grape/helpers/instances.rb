module Document
  module Grape
    module Helpers
      module Instances

        def self.included base
          base.helpers HelperMethods
        end

        module HelperMethods

          def virtual_model
            @virtual_model ||= form.to_virtual_model
          end

          def heavy_search
            params[:heavy_search]
          end

          def advanced_search_params
            (params.permit![:advanced_search] || []).map(&:to_h)
          end

          def simple_advanced_search_params
            (params.permit![:simple_advanced_search] || []).map(&:to_h)
          end

          def step
            params[:step]
          end

          def last_step
            step.to_i + 1 == form.step_options.total
          end

          def first_step
            step.to_i == 0
          end

          def activate_step_form
            if form.step
              if step
                form.activate_step step.to_i
              else
                form.activate_step_from_uid params[:id]
              end
            end
          end

          def instance_params
            posts.permit!
          end

          def instance
            return @instance if @instance
            @instance = params[:id] ? query_scope.find(params[:id]) : virtual_model.new(instance_params)
            Document.callbacks.perform(:instance_got_resource, self, @instance)
          end

          def query_scope
            query = Document.callbacks.perform(:instance_query_scope, self, virtual_model)
            query
          end

        end

      end
    end
  end
end