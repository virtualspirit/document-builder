module Document
  module Concerns
    module Models
      module ActsAsGridField
        extend ActiveSupport::Concern

        included  do
          has_many :grid_fields, class_name: "Document::Grids::Field", foreign_key: "field_id", dependent: :destroy

          after_initialize :set_previous_document_form_id, if: :persisted?
          after_create :create_gried_field
          after_update :update_grid_field

        end

        def set_previous_document_form_id
          if depedency_field?
            @previous_document_form_id= options.document_form_id
          end
        end

        def create_gried_field
          form.grids.each do |grid|
            grid.add_field self
          end
        end

        def update_grid_field
          grid_fields.each do |gf|
            if name_previously_changed? || label_previously_changed? || position_previously_changed?
              gf.update(name: name, label: label, position: position)
              if depedency_field?
                if @previous_document_form_id.present?
                  current_df = options.document_form_id
                  if @previous_document_form_id != current_df
                    gf.grids.each(&:destroy)
                    gf.create_default_grids
                  end
                end
              end
            end
          end
        end

      end
    end
  end
end
