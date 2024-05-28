module Document
  module Concerns
    module Models
      module Cachers

        module BareForm
          extend ActiveSupport::Concern
          included do
            cache_self

            cache_at :fields#, -> (id) { Document::Field.where(form_id: id) }, expire_by: :fields
            cache_at :sections#, -> (id) { Document::Section.where(form_id: id) }, expire_by: :sections
            cache_at :attachable#, -> (attachable_id) { Document::Field.find(attachable_id) }, expire_by: "Document::Field#id", primary_key: :attachable_id

            cache_at :grids, -> (id) { Document::Grid.where(form_id: id) }, expire_by: :grids
            cache_at :grid_lists, -> (id){ Document::Grids::List.where(form_id: id) }, expire_by: :grid_lists
            cache_at :grid_panels, -> (id){ Document::Grids::Panel.where(form_id: id) }, expire_by: :grid_lists
            cache_at :default_grid_panel, -> { Document::Grids::Panel.find_by(form_id: id, default:true) }, expire_by: :default_grid_panel
            cache_at :default_grid_list#, -> { default_grid_list }, expire_by: :default_grid_list

            {
              'fields' => 'fields_unloaded', 'sections'=> 'sections_unloaded', 'attachable'=> 'attachable_unloaded',
              'grids' => "grids", 'grid_lists' => 'grid_lists', 'grid_panels' => 'grid_panels', 'default_grid_panel' => 'default_grid_panel', 'default_grid_list' => 'default_grid_panel'
            }.each do |c, m|
              class_eval <<-CODE, __FILE__, __LINE__ + 1
                def cached_#{c}
                  return send('#{c}')
                  begin
                    cacher.send('#{c}')
                  rescue => e
                    cacher.clean('#{c}'.to_sym)
                    send('#{m}')
                  end
                end
              CODE
            end

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

            {'fields' => 'fields_unloaded', 'form' => 'form_unloaded' }.each do |c,m|
              class_eval <<-CODE, __FILE__, __LINE__ + 1
                def cached_#{c}
                  return send('#{c}')
                  begin
                    cacher.send('#{c}')
                  rescue => e
                    cacher.clean('#{c}'.to_sym)
                    send('#{m}')
                  end
                end
              CODE
            end

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

            cache_at :grid_fields#, -> { grid_fields.to_a }, expire_by: :grid_fields
            cache_at :default_grid_field#, -> { default_grid_field }, expire_by: :default_grid_field

            {'form' => 'form_unloaded', 'section' => 'section_unloaded', 'nested_form' => 'nested_form_unloaded', 'grid_fields' => 'grid_fields', 'default_grid_field' => 'default_grid_field' }.each do |c,m|
              class_eval <<-CODE, __FILE__, __LINE__ + 1
                def cached_#{c}
                  return send('#{c}')
                  begin
                    cacher.send('#{c}')
                  rescue => e
                    cacher.clean('#{c}'.to_sym)
                    send('#{m}')
                  end
                end
              CODE
            end
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

            {'form' => 'form_unloaded', 'sections' => 'sections_unloaded', 'nested_fields' => 'nested_fields', 'fields' => 'fields' }.each do |c,m|
              class_eval <<-CODE, __FILE__, __LINE__ + 1
                def cached_#{c}
                  return send('#{c}')
                  begin
                    cacher.send('#{c}')
                  rescue => e
                    cacher.clean('#{c}'.to_sym)
                    if '#{c}' == 'fields'
                      send('#{m}').to_a
                    elsif '#{c}' == 'nested_fields'
                      send('#{m}').to_a
                    else
                      send('#{m}')
                    end
                  end
                end
              CODE
            end

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

            {'grids' => 'grids', 'field' => 'field_unloaded', 'section' => 'section_unloaded', 'nested_grid_list' => 'nested_grid_list', 'nested_grid_panel' => 'nested_grid_panel'}.each do |c,m|
              class_eval <<-CODE, __FILE__, __LINE__ + 1
                def cached_#{c}
                  return send('#{c}')
                  begin
                    cacher.send('#{c}')
                  rescue => e
                    cacher.clean('#{c}'.to_sym)
                    if '#{c}' == 'grids'
                      send('#{m}').to_a
                    else
                      send('#{m}')
                    end
                  end
                end
              CODE
            end

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