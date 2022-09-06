module Document
  module Concerns
    module Models
      module Form
        extend ActiveSupport::Concern

        included do

          attr_accessor :step_state

          after_destroy do
            unset_constant virtual_model_name
          end
          after_update do
            if saved_change_to_name?
              unset_constant virtual_model_name
            end
          end
        end

        def activate_step_from_uid uid
          fs = Document::FormStep.where(document_uid: uid).first
          if fs
            if self.step_options.total < fs.step
              activate_step self.step_options.total
            else
              activate_step fs.step
            end
          else
            activate_step 0
          end
        end

        def activate_step current_step = 0
          self.step_state = current_step
        end

        def deactivate_step
          step_state= nil
        end

        def step_active?
          step_state != nil
        end

        def to_virtual_model(model_name: virtual_model_name,
                            fields_scope: proc { |fields| fields },
                            overrides: {})
        if step_active?
          fields_scope = proc {|fields|
          section = sections.select{|sect| sect.position_rank == step_state }.first
          unless section
            section = sections.first
          end
          section.try(:fields) || fields
          }
        end
          model = virtual_model model_name
          set_constant model_name, model
          append_to_virtual_model(model, fields_scope: fields_scope, overrides: overrides)
        end

        def append_to_virtual_model(model,
                                    fields_scope: proc { |fields| fields },
                                    overrides: {})
          check_model_validity! model

          global_overrides = overrides.fetch(:_global, {})
          fields_scope.call(fields).each do |f|
            f.interpret_to model, overrides: global_overrides.merge(overrides.fetch(f.name, {}))
          end
          if self.is_a?(::Document::Form)
            model.search_in model.get_searchable_fields
          end
          model
        end


        def append_to_virtual_model(model, fields_scope: proc { |fields| fields }, overrides: {})
          global_overrides = overrides.fetch(:_global, {})
          fields_scope.call(fields).each do |f|
            f.interpret_to model, overrides: global_overrides.merge(overrides.fetch(f.name, {}))
          end
          if self.is_a?(::Document::Form)
            model.search_in model.get_searchable_fields
          end
          model
        end

        protected

          def virtual_model_name
            "#{name}#{id}".classify
          end

          def virtual_model model_name
            model = Document.virtual_model_class.build name: model_name, collection: "#{self.class.name.demodulize.downcase}-#{id}", step: step_active?
            model.form_id = self.id
            model
          end

          def set_constant model_name, model
            unset_constant model_name if Object.const_defined?(model_name)
            Object.const_set(model_name, model)
          end

          def unset_constant model_name
            if Object.const_defined?(model_name)
              Object.send(:remove_const, model_name)
            end
          end

        private

          def check_model_validity!(model)
            unless model.is_a?(Class) && model < ::Document::VirtualModel
              raise ArgumentError, "#{model} must be a #{::Document::VirtualModel}'s subclass"
            end
          end
      end
    end
  end
end
