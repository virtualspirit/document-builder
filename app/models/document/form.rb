module Document
  class Form < BareForm

    belongs_to :owner, polymorphic: true, optional: true
    belongs_to :documentable, polymorphic: true, optional: true
    has_many :sections, -> { order(:position) }, class_name: Fbuilder.config.document.section_model_class, dependent: :destroy, inverse_of: :form, index_errors: true, counter_cache: :sections_count
    accepts_nested_attributes_for :sections, allow_destroy: true

    include Document::Concerns::Models::Cachers::Form

    serialize :step_options, FormStepOptions

    before_save do
      if will_save_change_to_attribute?(:step)
        if step
          step_options.total = sections.count
        end
      end
    end

    after_initialize do
      if respond_to? :step_options
        self.step_options ||= {}
      end
    end

    alias_method :segments=, :sections_attributes=
    alias_method :steps, :sections
    alias_method :steps=, :sections_attributes=

    NAME_REGEX = /\A[a-z][a-z_0-9]*\z/.freeze

    validates :name,
              presence: true,
              uniqueness: { scope: [:documentable_id, :documentable_type] },
              exclusion: { in: Document.reserved_names },
              format: { with: NAME_REGEX }

    validates :title, presence: true
    validates :name, presence: true

    attr_accessor :skip_default_section

    after_create :auto_create_default_section, unless: :skip_default_section

    private

      def auto_create_default_section
        if sections.blank?
          sections.create! title: I18n.t("defaults.section.title"), headless: true
        end
      end

  end
end
