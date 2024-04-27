module Document
  module Grids
    class Panel < Document::Grid

      has_many :sections, -> { rank(:position) }, class_name: "Document::Grids::Section", foreign_key: "grid_id", dependent: :destroy, index_errors: true
      accepts_nested_attributes_for :sections, allow_destroy: true

      #before_create :append_sections

      def is_panel?
        true
      end

      def add_field field, namespace: [], persist: true
        gf = Document::Grids::Field.build(field, namespace)
        # if field.section
        #   gf.section = sections.find_by(section_id: field.section_id)
        # end
        gf.grid = self
        gf.save if persist
        gf
      end

      def append_section(section)
        sections.build(title: section.title, position: section.position, description: section.description, section_id: section.id, headless: section.headless)
      end

      def append_sections
        if viewable.type == "Document::Form"
          viewable.sections.each do |s|
            append_section(s)
          end
        end
      end

    end
  end
end