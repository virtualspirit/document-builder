module Document
  module Concerns
    module Models
      module Cachers

        module BareForm
          extend ActiveSupport::Concern
          included do
            cache_self
            cache_at :fields, ->{ fields_unloaded }, expire_by: :fields
            cache_at :sections, -> { sections_unloaded }, expire_by: :sections
            cache_at :attachable, -> { attachable_unloaded }, expire_by: :attachable

            cache_at :grids, -> {  grids.to_a }, expire_by: :grids
            cache_at :grid_lists, -> { grid_lists.to_a }, expire_by: :grid_lists
            cache_at :grid_panels, -> { grid_panels.to_a }, expire_by: :grid_panels
            cache_at :default_grid_panel, -> { default_grid_panel }, expire_by: :default_grid_panel
            cache_at :default_grid_list, -> { default_grid_list }, expire_by: :default_grid_list

          end

          def fields_unloaded
            fields.map(&:prepared_for_caching)
          end

          def sections_unloaded
            sections.map(&:prepared_for_caching)
          end

          def attachable_unloaded
            if type == "Document::NestedForm"
              attachable.try(:prepared_for_caching)
            end
          end

          def prepared_for_caching
            association(:fields).reset
            association(:sections).reset
            association(:attachable).reset if type == 'Document::NestedForm'
            association(:grids).reset
            association(:grid_lists).reset
            association(:grid_panels).reset
            association(:default_grid_list).reset
            association(:default_grid_panel).reset
            @permission_set_class = nil
            unset_constant(virtual_model_name)
            self
          end

        end

        module NestedForm
          extend ActiveSupport::Concern
          included do

          end
        end

        module Section
          extend ActiveSupport::Concern
          included do
            cache_self
            cache_at :form, ->{ form_unloaded }, expire_by: :form
            cache_at :fields, ->{ fields_unloaded }, expire_by: :fields
          end

          def prepared_for_caching
            association(:form).reset
            association(:fields).reset
            self
          end

          def form_unloaded
            form.prepared_for_caching if form
          end

          def fields_unloaded
            fields.map(&:prepared_for_caching)
          end

        end

        module Field
          extend ActiveSupport::Concern
          included do
            cache_self
            cache_at :form, ->{ form_unloaded }, expire_by: :form
            cache_at :section, ->{ section_unloaded }, expire_by: :section
            cache_at :nested_form, -> { nested_form_unloaded }, expire_by: :nested_form

            cache_at :grid_fields, -> { grid_fields.to_a }, expire_by: :grid_fields
            cache_at :default_grid_field, -> { default_grid_field }, expire_by: :default_grid_field
          end

          def form_unloaded
            form.prepared_for_caching
          end

          def section_unloaded
            section.prepared_for_caching if section
          end

          def nested_form_unloaded
            if attached_nested_form?
              nested_form.prepared_for_caching if nested_form
            end
          end

          def prepared_for_caching
            association(:form).reset
            association(:section).reset
            association(:nested_form).reset if attached_nested_form?
            association(:grid_fields).reset
            association(:default_grid_field).reset
            options.reset_form if depedency_field?
            self
          end

        end

        module Grid
          extend ActiveSupport::Concern
          included do
            cache_self
            cache_at :fields, -> { fields.to_a }, expire_by: :grid_fields
            cache_at :sections, -> { sections_unloaded }, expire_by: :form
            cache_at :nested_fields, -> { nested_fields.to_a }, expire_by: :grid_nested_fields

            cache_at :form, -> { form_unloaded }, expire_by: :form

            after_save do
              grid_fields.touch_all
              grid_nested_fields.touch_all
            end

          end
          def form_unloaded
            form.prepared_for_caching if form
          end

          def sections_unloaded
            sections.map(&:prepared_for_caching)
          end

        end

        module GridField
          extend ActiveSupport::Concern
          included do
            cache_self
            cache_at :grids, -> { grids.to_a }, expire_by: :grid_fields
            cache_at :field, -> { field_unloaded }, expire_by: :field
            cache_at :section, -> { section_unloaded }, expire_by: :section
            cache_at :nested_grid_list, -> { nested_grid_list }, expire_by: :grid_list_nested_field
            cache_at :nested_grid_panel, -> { nested_grid_panel }, expire_by: :grid_panel_nested_field

            after_save do
              grid_fields.touch_all
              if nested?
                grid_list_nested_field.try :touch
                grid_panel_nested_field.try :touch
              end
            end

          end

          def field_unloaded
            field.prepared_for_caching if field
          end

          def section_unloaded
            section.prepared_for_caching if section
          end

        end

      end
    end
  end
end