module Document
  module Concerns
    module Models
      module ActsAsGridField
        extend ActiveSupport::Concern

        included  do
          has_many :grid_fields, class_name: "Document::Grids::Field", foreign_key: "field_id", dependent: :destroy
          has_one :default_grid_field, -> { where(default: true) }, class_name: "Document::Grids::Field", foreign_key: "field_id", dependent: :destroy

          after_initialize :set_previous_document_form_id, if: :persisted?
          after_create :append_default_grid_field_to_grids
          after_update :update_grid_field

        end

        def set_previous_document_form_id
          if depedency_field?
            @previous_document_form_id= options.document_form_id
          end
        end

        def append_default_grid_field_to_grids
          gf = create_or_get_default_gried_field
          form.grids.only_default.each do |grid|
            grid.append_field gf
          end
        end

        def create_or_get_default_gried_field
          gf = default_grid_field
          unless gf
            gf = Document::Grids::Field.build(self)
            gf.default = true
            gf.default_aggregation = true
            self.default_grid_field= gf
            if attached_nested_form?
              if nested_form && nested_form.persisted?
                if type == "Document::Fields::MultipleNestedFormField"
                  nested_form.create_or_get_default_grid_list(gf)
                end
                nested_form.create_or_get_default_grid_panel(gf)
              end
            end
            if depedency_field?
              if options.form
                if type == "Document::Fields::DepedencyManyField"
                  options.form.create_or_get_default_grid_list(gf)
                end
                options.form.create_or_get_default_grid_panel(gf)
              end
            end
          end
          gf
        end

        def update_grid_field
          gf = create_or_get_default_gried_field
          if label_previously_changed? || position_on_section_previously_changed?
            gf.update(label: label, position_on_section: position_on_section)
          end
          if position_on_form_previously_changed?
            gf.grid_fields.each do |g|
              g.update position: position_on_form_rank
            end
          end
          if depedency_field?
            if @previous_document_form_id.present?
              current_df = options.document_form_id
              if @previous_document_form_id != current_df
                gf.grid_nested_fields.each(&:destroy)
                if type == "Document::Fields::DepedencyManyField"
                  options.form.create_or_get_default_grid_list(gf)
                end
                options.form.create_or_get_default_grid_panel(gf)
              end
            end
          end
        end

      end
    end
  end
end
