module Document
  module Concerns
    module Models
      module ActsAsGridSection
        extend ActiveSupport::Concern

        included  do
          has_many :grid_fields, class_name: "Document::Grids::Field", foreign_key: "section_id"
          # has_many :grid_sections, class_name: "Document::Grids::Section", foreign_key: "section_id", dependent: :destroy

          # after_create :create_grid_section
          # after_update :update_grid_section

          # def create_grid_section
          #   form.grids.where(type: "Document::Grids::Panel").each do |grid|
          #     grid.sections.create(
          #       title: title,
          #       description: description,
          #       position: position,
          #       headless: headless,
          #       grid: grid,
          #       section: self
          #     )
          #   end
          # end

          # def update_grid_section
          #   grid_sections.each do |sf|
          #     if title_previously_changed? || description_previously_changed? || position_previously_changed? || headless_previously_changed?
          #       sf.update(
          #         title: title,
          #         description: description,
          #         position: position,
          #         headless: headless,
          #       )
          #     end
          #   end
          # end

        end

      end
    end
  end
end