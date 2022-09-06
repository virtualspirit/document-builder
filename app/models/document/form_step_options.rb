module Document
  class FormStepOptions < Document::FieldOptions

    attribute :non_linear, :boolean, default: false
    attribute :total, :integer, default: 0

  end
end