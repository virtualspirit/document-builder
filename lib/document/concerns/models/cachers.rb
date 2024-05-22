module Document
  module Concerns
    module Models
      module Cachers

        module BareForm
          extend ActiveSupport::Concern
          included do
            cache_self
            cache_at :fields, ->{ fields }, expire_by: :fields
            cache_at :sections, -> { sections }, expire_by: :sections
            cache_at :attachable, -> { attachable }, expire_by: :attachable

            cache_at :grids, -> {  grids }, expire_by: :grids
            cache_at :grid_lists, -> { grid_lists }, expire_by: :grid_lists
            cache_at :grid_panels, -> { grid_panels }, expire_by: :grid_panels
            cache_at :default_grid_panel, -> { default_grid_panel }, expire_by: :default_grid_panel
            cache_at :default_grid_list, -> { default_grid_list }, expire_by: :default_grid_list
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
            cache_at :form, ->{ form }, expire_by: :form
            cache_at :fields, ->{ fields }, expire_by: :fields
          end
        end

        module Field
          extend ActiveSupport::Concern
          included do
            cache_self
            cache_at :form, ->{ form }, expire_by: :form
            cache_at :section, ->{ section }, expire_by: :section

            cache_at :grid_fields, -> { grid_fields }, expire_by: :grid_fields
            cache_at :default_grid_field, -> { default_grid_field }, expire_by: :default_grid_field
          end
        end

        module Grid
          extend ActiveSupport::Concern
          included do
            cache_self
            cache_at :fields, -> { fields }, expire_by: :grid_fields
            cache_at :sections, -> { sections }, expire_by: :form
            cache_at :nested_fields, -> { nested_fields }, expire_by: :grid_nested_fields

            cache_at :form, -> { form }, expire_by: :form

            after_save do
              grid_fields.touch_all
              grid_nested_fields.touch_all
            end

          end
        end

        module GridField
          extend ActiveSupport::Concern
          included do
            cache_self
            cache_at :grids, -> { grids }, expire_by: :grid_fields
            cache_at :field, -> { field }, expire_by: :field
            cache_at :section, -> { section }, expire_by: :section
            cache_at :nested_grid_list, -> { nested_grid_list }, expire_by: :grid_list_nested_field
            cache_at :nested_grid_panel, -> { nested_panel_list }, expire_by: :grid_panel_nested_field

            after_save do
              grid_fields.touch_all
              if nested?
                grid_list_nested_field.try :touch
                grid_panel_nested_field.try :touch
              end
            end

          end
        end

      end
    end
  end
end