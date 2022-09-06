module Document
  module Fields::Options
    class SelectField < BaseOptions
      attribute :strict, :boolean, default: true
      embeds_many :choices, class_name: "Document::Fields::Options::SelectField::Choice"
      accepts_nested_attributes_for :choices, reject_if: :all_blank, allow_destroy: true
      alias_method :selections=, :choices_attributes=
      alias_method :selections, :choices

      class Choice < Document::FieldOptions

        attribute :label, :string
        attribute :value, :string

      end
    end
  end
end
