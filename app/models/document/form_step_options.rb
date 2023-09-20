module Document
  class FormStepOptions < Document::FieldOptions

    attribute :non_linear, :boolean, default: false
    attribute :total, :integer, default: 0

    validates :non_linear, inclusion: { in: [0,1, false, true], allow_nil: true }

  end
end