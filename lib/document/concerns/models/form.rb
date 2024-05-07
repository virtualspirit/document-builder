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

        def get_current_step_from_uid uid
          fs = Document::FormStep.where(document_uid: uid).first
          fs.try(:step).to_i
        end

        def activate_step_from_uid uid
          current_step = get_current_step_from_uid uid
          unless self.step_options.total < current_step
            activate_step current_step
          end
          # if fs
          #   if self.step_options.total < fs.step
          #     activate_step self.step_options.total
          #   else
          #     activate_step fs.step
          #   end
          # else
          #   activate_step 0
          # end
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

        def active_step_section
          if step_active?
            [sections.rank(:position)[step_state]]
          end
        end

        def to_virtual_view(model_name: virtual_view_model_name, fields_scope: proc{|fields| fields}, overrides: {})
          model = _virtual_model model_name
          set_constant model_name, model
          append_to_virtual_view(model, fields_scope: fields_scope, overrides: overrides)
          model
        end

        def append_to_virtual_view model, fields_scope: proc { |fields| fields }, overrides: {}
          check_model_validity! model
          global_overrides = overrides.fetch(:_global, {})
          fields_scope.call(fields).each do |f|
            f.interpret_as_field_for model, overrides: global_overrides.merge(overrides.fetch(f.name, {}))
          end
          if self.is_a?(::Document::Form)
            model.search_in model.get_searchable_fields
          end
          model
        end

        def to_virtual_model(model_name: virtual_model_name,
                            fields_scope: proc { |fields| fields },
                            overrides: {})
          if step_active?
            fields_scope = proc {|fields|
              section = sections.select{|sect| sect.position_rank == step_state }.first
              section.try(:fields) || []
            }
          end
          model = _virtual_model model_name
          set_constant model_name, model
          model = append_to_virtual_model(model, fields_scope: fields_scope, overrides: overrides)          
          model.class_eval <<-CODE
            def serializable_hash(options= nil)
              relations = [:has_one, :belongs_to, :has_many, :has_and_belongs_to_many].reduce([]) { |arr, rel| arr + self.class.reflect_on_all_associations(rel).map(&:name) } 
              unless relations.blank?
                options ||= {}
                if options[:include].is_a?(Array)
                  options[:include] = [options[:include]].compact unless options[:include].is_a?(Array)
                  options[:include] = options[:include] + relations
                else
                  options[:include] = relations
                end
              end
              hash = super(options)
              self.class.reflect_on_all_associations(:embeds_one).map(&:name).each do |rname|            
                unless hash.keys.include?(rname.to_s)
                  hash[rname.to_s] = nil
                end
              end
              self.class.reflect_on_all_associations(:embeds_many).map(&:name).each do |rname|
                unless hash.keys.include?(rname.to_s)
                  hash[rname.to_s] = []
                end
              end
              (self.class._uploadable_config[self.class.name] || {}).each do |f,v|
                hash[f] = self.send("_"+f.to_s+"_url") rescue {}
              end
              hash
            end
          CODE
          model
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

        def virtual_model
          Object.const_get(virtual_model_name) rescue to_virtual_model
        end

        def virtual_view
          Object.const_get(virtual_view_model_name) rescue to_virtual_view
        end

        # def append_to_virtual_model(model, fields_scope: proc { |fields| fields }, overrides: {})
        #   global_overrides = overrides.fetch(:_global, {})
        #   fields_scope.call(fields).each do |f|
        #     f.interpret_to model, overrides: global_overrides.merge(overrides.fetch(f.name, {}))
        #   end
        #   if self.is_a?(::Document::Form)
        #     model.search_in model.get_searchable_fields
        #   end
        #   model
        # end

        def collection_name
          "#{self.class.name.demodulize.downcase}-#{id}"
        end

        protected

          def virtual_model_name
            "#{name}#{id.to_s.underscore}".classify
          end

          def virtual_view_model_name
            "#{name.classify}#{id.to_s.underscore}".classify
          end

          def _virtual_model model_name
            model = Document.virtual_model_class.build name: model_name, collection: collection_name, step: step_active?
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
