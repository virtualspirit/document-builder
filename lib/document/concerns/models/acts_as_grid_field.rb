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
          gf = _create_default_gried_field
          form.grids.only_default.each do |grid|
            grid.append_field gf
          end
        end

        def _create_default_gried_field
          gf = Document::Grids::Field.build(self)
          gf.default = true
          gf.default_aggregation = true
          gf.field = self        
          gf.save
          if attached_nested_form?
            if nested_form
              if type == "Document::Fields::MultipleNestedFormField"                
                nested_form._create_default_grid_list(gf)
              end
              nested_form._create_default_grid_panel(gf)
            end
          end
          if depedency_field?
            if options.form
              if type == "Document::Fields::DepedencyManyField"                
                options.form._create_default_grid_list(gf)
              end
              options.form._create_default_grid_panel(gf)

            end
          end
          gf
        end

        def update_grid_field
          gf = default_grid_field || _create_default_gried_field
          if name_previously_changed? || label_previously_changed? || position_previously_changed?
            gf.update(name: name, label: label, position: position)
          end
          if depedency_field?
            if @previous_document_form_id.present?
              current_df = options.document_form_id
              if @previous_document_form_id != current_df
                gf.nested_grids.each(&:destroy)
                gf.create_default_grids
              end
            end
          end          
        end

      end
    end
  end
end
