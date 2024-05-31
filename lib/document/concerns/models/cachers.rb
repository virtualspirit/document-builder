module Document
  module Concerns
    module Models
      module Cachers

        module BareForm
          extend ActiveSupport::Concern
          included do
            cache_self
            cache_at :fields
            cache_at :grids
            cache_at :grid_lists
            cache_at :grid_panels
            cache_at :default_grid_panel
            cache_at :default_grid_list

            [ 'fields','grids', 'grid_lists', 'grid_panels', 'default_grid_list', 'default_grid_panel'].each do |c|
              class_eval <<-CODE, __FILE__, __LINE__ + 1
                def cached_#{c}
                  return send('#{c}')
                  begin
                    val = cacher.send('#{c}')
                    if val.blank?
                      cacher.clean('#{c}'.to_sym)
                    end
                    val = cacher.send('#{c}')
                  rescue => e
                    cacher.clean('#{c}'.to_sym)
                    send('#{c}')
                  end
                end
              CODE
            end

            # after_commit on: [:update, :destroy] do
            #   self.class.base_class.cacher.clean_by id: id
            # end

          end

        end

        module Form
          extend ActiveSupport::Concern
          included do
            include BareForm

            cache_at :sections#, -> (id) { Document::Section.where(form_id: id) }, expire_by: :sections

            [
              'sections'
            ].each do |c|
              class_eval <<-CODE, __FILE__, __LINE__ + 1
                def cached_#{c}
                  begin
                    return send('#{c}')
                    val = cacher.send('#{c}')
                    if val.blank?
                      cacher.clean('#{c}'.to_sym)
                    end
                    val = cacher.send('#{c}')
                  rescue => e
                    cacher.clean('#{c}'.to_sym)
                    send('#{c}')
                  end
                end
              CODE
            end

          end

        end

        module NestedForm
          extend ActiveSupport::Concern
          included do
            include BareForm
            cache_at :attachable

            [
              'attachable'
            ].each do |c|
              class_eval <<-CODE, __FILE__, __LINE__ + 1
                def cached_#{c}
                  begin
                    return send('#{c}')
                    val = cacher.send('#{c}')
                    if val.blank?
                      cacher.clean('#{c}'.to_sym)
                    end
                    val = cacher.send('#{c}')
                  rescue => e
                    cacher.clean('#{c}'.to_sym)
                    send('#{c}')
                  end
                end
              CODE
            end

            # after_commit on: :create do
            #   if cached_attachable
            #     cached_attachable.cacher.clean(:nested_form)
            #   end
            # end
          end
        end

        module Section
          extend ActiveSupport::Concern
          included do
            cache_self
            cache_at :form
            cache_at :fields

            ['fields', 'form'].each do |c|
              class_eval <<-CODE, __FILE__, __LINE__ + 1
                def cached_#{c}
                  begin
                    return send('#{c}')
                    val = cacher.send('#{c}')
                    if val.blank?
                      cacher.clean('#{c}'.to_sym)
                    end
                    val = cacher.send('#{c}')
                  rescue => e
                    cacher.clean('#{c}'.to_sym)
                    send('#{c}')
                  end
                end
              CODE
            end

            # after_commit on: [:update, :destroy] do
            #   self.class.base_class.cacher.clean_by id: id
            # end
          end

        end

        module Field
          extend ActiveSupport::Concern
          included do
            cache_self
            cache_at :form
            cache_at :section
            cache_at :nested_form

            cache_at :grid_fields
            cache_at :default_grid_field

            ['form','section', 'nested_form', 'grid_fields', 'default_grid_field'].each do |c|
              class_eval <<-CODE, __FILE__, __LINE__ + 1
                def cached_#{c}
                  begin
                    return send('#{c}')
                    val = cacher.send('#{c}')
                    if val.blank?
                      cacher.clean('#{c}'.to_sym)
                    end
                    val = cacher.send('#{c}')
                  rescue => e
                    cacher.clean('#{c}'.to_sym)
                    send('#{c}')
                  end
                end
              CODE
            end

            # after_commit on: :create do
            #   cached_form.cacher.clean_fields if cached_form
            #   if section_id.present?
            #     cached_section.try(:cacher).try(:clean_fields)
            #   end
            # end

            # after_commit :on => [:update, :destroy] do
            #   self.class.base_class.cacher.clean_by id: id
            #   cached_form.cacher.clean_fields if cached_form
            #   if section_id.present?
            #     cached_section.try(:cacher).try(:clean_fields)
            #   end
            #   cached_nested_form.cacher.clean_attachable if attached_nested_form? && cached_nested_form
            #   cached_grid_fields.each{|gf| gf.cacher.clean_field }
            # end

          end

        end

        module Grid
          extend ActiveSupport::Concern
          included do
            cache_self
            cache_at :fields
            cache_at :sections
            cache_at :nested_fields
            cache_at :form

            ['form', 'sections', 'nested_fields', 'fields' ].each do |c|
              class_eval <<-CODE, __FILE__, __LINE__ + 1
                def cached_#{c}
                  begin
                    return send('#{c}')
                    val = cacher.send('#{c}')
                    if val.blank?
                      cacher.clean('#{c}'.to_sym)
                    end
                    val = cacher.send('#{c}')
                  rescue => e
                    cacher.clean('#{c}'.to_sym)
                    send('#{c}')
                  end
                end
              CODE
            end

            # after_save do
            #   grid_fields.touch_all
            #   grid_nested_fields.touch_all
            # end

            # after_commit on: :create do
            #   cached_fields.each{|gf| gf.cacher.clean_grids }
            # end

            # after_commit on: [:update, :destroy] do
            #   self.class.base_class.cacher.clean_by id: id
            #   if cached_form
            #     cached_form.cacher.clean_default_grid_panel if is_panel?
            #     cached_form.cacher.clean_default_grid_list if is_list?
            #   end
            #   cached_fields.each{|gf| gf.cacher.clean_grids }
            #   cached_nested_fields.each{|nf|
            #     nf.cacher.clean_nested_grid_list
            #     nf.cacher.clean_nested_grid_panel
            #   }
            # end

          end

        end

        module GridField
          extend ActiveSupport::Concern
          included do
            cache_self
            cache_at :grids
            cache_at :field
            cache_at :section
            cache_at :nested_grid_list
            cache_at :nested_grid_panel

            ['grids', 'field', 'section', 'nested_grid_list', 'nested_grid_panel'].each do |c|
              class_eval <<-CODE, __FILE__, __LINE__ + 1
                def cached_#{c}
                  begin
                    return send('#{c}')
                    val = cacher.send('#{c}')
                    if val.blank?
                      cacher.clean('#{c}'.to_sym)
                    end
                    val = cacher.send('#{c}')
                  rescue => e
                    cacher.clean('#{c}'.to_sym)
                    send('#{c}')
                  end
                end
              CODE
            end

            # after_commit on: [:update, :destroy] do
            #   self.class.base_class.cacher.clean_by id: id
            #   cached_grids.each{|g| g.cacher.clean_fields }
            #   cached_nested_grid_list.cacher.clean_nested_fields if cached_nested_grid_list
            #   cached_nested_grid_panel.cacher.clean_nested_fields if cached_nested_grid_panel
            # end

          end

        end

      end
    end
  end
end