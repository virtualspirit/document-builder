module Document
  module Concerns
    module Models
      module CachersBackup

        module BareForm
          extend ActiveSupport::Concern
          included do
            cache_this :cached_fields do
              value do |form|
                form.fields.all.map(&:reload)
              end
              invalidate_when [:after_commit]
              before_invalidate do |form|
                form.cached_fields.each(&:invalidate_cache_of_cached_form)
              end
            end

            cache_this :cached_sections do
              value do |form|
                form.sections.all.map(&:reload)
              end
              invalidate_when [:after_commit]
              before_invalidate do |form|
                form.cached_sections.each(&:invalidate_cache_of_cached_form)
              end
            end

            cache_this :cached_grids do
              value do |form|
                form.grids.all.map(&:reload)
              end
              before_invalidate do |form|
                form.cached_grids.each(&:invalidate_cache_of_cached_form)
              end
            end

            cache_this :cached_default_grid_panel do
              value do |form|
                form.default_grid_panel.reload if form.default_grid_panel
              end
            end

            cache_this :cached_default_grid_list do
              value do |form|
                form.default_grid_list.reload if form.default_grid_list
              end
            end

            after_commit do
              cached_form.cached_grids.each(&:invalidate_cache_of_cached_form)
            end

            cache_at :fields_cache, ->{ fields }, expire_by: :fields

          end
        end

        module NestedForm
          extend ActiveSupport::Concern
          included do
            cache_this :cached_attachable do
              value do |form|
                form.attachable.try(:reload)
              end
              before_invalidate do |form|
                form.cached_attachable.try :invalidate_cache_of_cached_nested_form
              end
            end
          end
        end

        module Section
          extend ActiveSupport::Concern
          included do
            cache_this :cached_fields do
              value do |section|
                section.fields.all.map(&:reload)
              end
              before_invalidate do |section|
                section.cached_fields.each(&:invalidate_cache_of_cached_section)
              end
            end
            cache_this :cached_form do
              value do |section|
                section.form.try(:reload)
              end
              before_invalidate do |section|
                section.cached_form.try(:invalidate_cache_of_cached_sections)
              end
            end

            cache_this :cached_position_rank do
              value do |section|
                section.position_rank
              end
              invalidate_if do |section|
                section.position_before_last_save != section.position
              end
              before_invalidate do |section|
                cached_form.cached_sections.each(&:invalidate_cache_of_cached_position_rank)
                cached_form.cached_fields.each(&:invalidate_cache_of_cached_position_on_form_rank)
              end
            end
          end
        end

        module Field
          extend ActiveSupport::Concern
          included do
            cache_this :cached_form do
              value do |field|
                field.form
              end
              before_invalidate do |field|
                field.cached_form.try(:invalidate_cache_of_cached_fields)
              end
            end

            cache_this :cached_nested_form do
              value do |field|
                field.nested_form
              end
              before_invalidate do |field|
                field.cached_nested_form.try(:invalidate_cache_of_cached_attachable)
              end
            end

            cache_this :cached_section do
              value do |field|
                field.section
              end
              before_invalidate do |field|
                field.cached_section.try(:invalidate_cache_of_cached_fields)
              end
            end

            cache_this :cached_position_on_section_rank do
              value do |field|
                section.position_on_section_rank
              end
              invalidate_if do |field|
                field.position_on_section_before_last_save != field.position_on_section
              end
              before_invalidate do |field|
                field.cached_section.cached_fields.each(&:invalidate_cache_of_cached_position_on_section_rank)
              end
            end

            cache_this :cached_position_on_form_rank do
              value do |field|
                field.position_on_form_rank
              end
              invalidate_if do |field|
                field.position_on_form_before_last_save != field.position_on_form
              end
              before_invalidate do |field|
                field.cached_form.cached_fields.each(&:invalidate_cache_of_cached_position_on_form_rank)
              end
            end
          end
        end

        module Grid
          extend ActiveSupport::Concern
          included do
            cache_this :cached_form do
              value do |grid|
                grid.form.reload
              end
              before_invalidate do |grid|
                grid.cached_form.invalidate_cache_of_cached_grids
              end
            end

            cache_this :cached_fields do
              value do |grid|
                grid.fields.all.map(&:reload)
              end
            end

            cache_this :cached_sections do
              value do |grid|
                if grid.is_panel?
                  grid.sections.all.map(&:reload)
                else
                  []
                end
              end
            end
          end
        end

        module GridField
          extend ActiveSupport::Concern
          included do
            cache_this :cached_field do
              value do |field|
                if field.field_id
                  field.field.try(:reload)
                end
              end
              before_invalidate do |field|
                if field.field_id
                  field.cached_field.try(:invalidate_cache_of_cached_grid_field)
                end
              end
            end

            cache_this :cached_section do
              value do |field|
                if field.section_id
                  field.section.try(:reload)
                end
              end
              before_invalidate do |field|
                if field.section_id
                  field.cached_section.try(:invalidate_cache_of_cached_grid_fields)
                end
              end
            end
          end
        end

      end
    end
  end
end