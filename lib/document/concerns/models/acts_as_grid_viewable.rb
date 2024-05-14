module Document
  module Concerns
    module Models
      module ActsAsGridViewable
        extend ActiveSupport::Concern

        included  do
          has_many :grids, class_name: "Document::Grid", foreign_key: "form_id", dependent: :destroy
          has_many :grid_lists, class_name: "Document::Grids::List", foreign_key: "form_id"
          has_many :grid_panels, class_name: "Document::Grids::Panel", foreign_key: "form_id"
          has_one :default_grid_panel, -> { where(default: true) }, class_name: "Document::Grids::Panel", foreign_key: "form_id"
          has_one :default_grid_list, -> { where(default: true) }, class_name: "Document::Grids::List", foreign_key: "form_id"

          after_create :create_default_grids

        end

        def get_default_grid_panel
          grids
          .includes(*[:form, :sections, :fields => [ :field => [:nested_form], :nested_grid_panel => [:form, :sections, :fields], :nested_grid_list => [:form, :fields]]])
          .where(default: true, form_id: self.id, type: "Document::Grids::Panel")
          .first
        end

        def get_default_grid_list
          grids
          .includes(*[:form, :sections, :fields => [ :field => [:nested_form], :nested_grid_panel => [:form, :sections, :fields], :nested_grid_list => [:form, :fields]]])
          .where(default: true, form_id: self.id, type: "Document::Grids::List")
          .first
        end

        def create_default_grids
          if default_grid_panel.blank? && default_grid_list.blank?
            create_or_get_default_grids
          else
            [default_grid_panel, default_grid_list]
          end
        end

        def create_or_get_default_grids
          if type == "Document::Form"
            create_or_get_default_grid_list
            create_or_get_default_grid_panel
          end
          if type == "Document::NestedForm"
            if attachable.present?
              if attachable.type == 'Document::Fields::MultipleNestedFormField'
                create_or_get_default_grid_list(attachable.create_or_get_default_gried_field)
              end
              create_or_get_default_grid_panel(attachable.create_or_get_default_gried_field)
            end
          end
          [create_or_get_default_grid_panel, create_or_get_default_grid_list]
        end

        def create_or_get_default_grid_list(nested_field=nil)
          @list ||= default_grid_list
          unless @list
            @list = create_default_grid_list(default: true, name: grid_title)
            @list.grid_owners.create(owner: form.owner)
          end
          @list.nested_fields << nested_field if nested_field
          @list
        end

        def create_or_get_default_grid_panel(nested_field=nil)
          panel = default_grid_panel
          unless panel
            panel = create_default_grid_panel(default: true, name: grid_title, list: default_grid_list)
            panel.grid_owners.create(owner: form.owner)
          end
          panel.nested_fields << nested_field if nested_field
          panel
        end

        def grid_title
          if type == "Document::NestedForm"
            attachable.try(:label)
          else
            title
          end
        end

      end

    end
  end
end
