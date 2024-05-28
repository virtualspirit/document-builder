# create_table :document_grids do |t|
#   t.references :form, polymorphic: true
#   t.string :name
#   t.text :options
#   t.integer :order
#   t.string :type
#   t.text :options
#   t.boolean :default, default: false
#   t.timestamps
# end

# module Document
#   class Grid < ApplicationRecord

#     belongs_to :form, polymorphic: true
#     has_many :fields, class_name: "Document::Grids::Field", foreign_key: "grid_id", dependent: :destroy
#     accepts_nested_attributes_for :fields, allow_destroy: true

#     validates :name, presence: true
#     validates :type, presence: true, inclusion: { in: ['Document::Grids::List', 'Document::Grids::Panel'] }

#     def draw fields_collection = form.try(:fields) || [], namespace = []
#       fields_collection.each do |field|
#         self.fields << Document::Grids::Field.build(self, field, namespace)
#       end
#       self.fields
#     end

#     def virtual_view
#       if form
#         @virtual_view ||= form.to_virtual_view
#       end
#     end

#     def virtual_view!
#       if form
#         @virtual_view = form.to_virtual_view
#       end
#     end

#   end
# end

module Document
  class Grid < ApplicationRecord

    belongs_to :form, class_name: "Document::BareForm", foreign_key: "form_id", optional: true
    #belongs_to :nested_field, class_name: "Document::Grids::Field", foreign_key: "nested_field_id", optional: true
    #belongs_to :container, class_name: "Document::Grid", foreign_key: "container_id", optional: true
    has_many :nested_grids, class_name: "Document::Grid", foreign_key: "container_id"
    has_many :grid_fields, -> { rank(:field_position_on_grid) }, class_name: "Document::Grids::GridField", foreign_key: "grid_id", dependent: :destroy, inverse_of: :grid
    has_many :fields, through: :grid_fields, class_name: "Document::Grids::Field"
    has_many :grid_owners, class_name: "Document::GridOwner", foreign_key: "grid_id", dependent: :destroy
    #has_many :owners, through: :grid_owners, source: :owner
    has_many :sections, -> { rank(:position) }, through: :form, source: :sections
    has_many :grid_nested_fields, class_name: "Document::Grids::GridNestedField", foreign_key: "nested_grid_id"
    has_many :nested_fields, through: :grid_nested_fields, class_name: "Document::Grids::Field"
    has_many :query_builders, class_name: "Document::QueryBuilder", as: :configurable

    include Document::Concerns::Models::Cachers::Grid

    accepts_nested_attributes_for :fields, allow_destroy: true, reject_if: :all_blank

    validates :name, presence: true
    validates :form, presence: true#, unless: :nested_field
    #validates :nested_field, presence: true, unless: :form
    validates :default_aggregation, acceptance: true, if: :default

    validate do
      if form
        unless form.class.included_modules.include?(Document::Concerns::Models::ActsAsGridViewable)
          errors.add(:form, :invalid)
        end
      end
    end

    validate do
      unless type_was.nil?
        if type_was != type
          errors.add(:type, :invalid)
        end
      end
    end

    validate do
      unless options.valid?
        errors.add(:options, :invalid)
        options.errors.each {|e| errors.import e, **e.options.merge(attribute: "options.#{e.attribute}")}
      end
      unless aggregation.valid?
        errors.add(:aggregation, :invalid)
        aggregation.errors.each {|e| errors.import e, **e.options.merge(attribute: "aggregation.#{e.attribute}")}
      end
    end

    attr_accessor :nested_field, :prevent_default_destroy

    def prevent_default_destroy!
      self.prevent_default_destroy= true
    end

    before_destroy do
      if default && prevent_default_destroy
        errors.add(:default, :invalid)
        throw :abort
      end
    end

    after_create :append_default_fields, if: :default
    after_save do
      if form_id.present?
        if default && (default_previously_was == false || default_previously_was == nil)
          previous_default = self.class.where.not(id: self.id).where(default: true, form_id: form_id, type: self.type).each do |pd|#.update_all(default: false)
            pd.grid_nested_fields.update_all(nested_grid_id: self.id)
            pd.update_column(:default, false)
          end
        end
      end
    end

    def set_as_default
      update(default: true)
    end

    def virtual_view
      if cached_form
        @virtual_view ||= cached_form.to_virtual_view
      end
    end

    def is_panel?
      false
    end

    def is_list?
      false
    end

    def has_sections?
      is_panel? && cached_form.try(:type) == "Document::Form"
    end

    def append_field field
      self.fields << field
    end

    def append_default_fields
      gfs = []
      #cacher.form.fields.includes(:default_grid_field).each do |f|
      cached_form.fields.each do |f|
        gf = f.default_grid_field || f.create_or_get_default_gried_field
        gfs << gf
      end
      ##append timestamps
      gfs = gfs + Document::Grids::Field.timestamp_fields
      append_field gfs
    end

    def build_default_aggregation(grid_container=nil)
      if default_aggregation
        aggregation.stages = []
        aggregation.nested_stages = []
      end
    end

    def aggregation_stages(params={}, field_scope = proc{|field, grid| field})
      stages = fields_stages(field_scope)
      if scopes_stage = default_scopes_aggregation_stage
        stages << scopes_stage
      end
      stages
    end

    def to_aggregation(params={}, field_scope = proc{|field, grid| field})
      if default_aggregation
        build_default_aggregation
      end
      agg = aggregation
      agg.stages.append(aggregation_stages(params, field_scope))
      agg.to_aggregation
    end

    def fields_stages(field_scope= proc{|field, grid| field})
      stages = []
      _fields= field_scope.call(cached_fields, self)
      _fields.each do |field|
        field.build_default_aggregation if field.default_aggregation
        stages = stages + field.aggregation.stages
      end
      stages << Document::Grids::AggregationStage.new(name: "$project", order: 9999, arguments_attributes: [{function: "version", parameter: 1}])
      if cached_form.step?
        stages << Document::Grids::AggregationStage.new(name: "$project", order: 9999, arguments_attributes: [{function: "_step", parameter: 1}])
        stages << Document::Grids::AggregationStage.new(name: "$project", order: 9999, arguments_attributes: [{function: "_current_step", parameter: 1}])
        stages << Document::Grids::AggregationStage.new(name: "$project", order: 9999, arguments_attributes: [{function: "_total_step", parameter: 1}])
        stages << Document::Grids::AggregationStage.new(name: "$project", order: 9999, arguments_attributes: [{function: "_steps_keywords", parameter: 1}])
      end
      stages
    end

    def nested_aggregation_stages(params={}, field_scope = proc{|field, grid| field})
      stages = []
      if nested_field
        build_default_aggregation if default_aggregation
        stages = aggregation.nested_stages.map{|stg|
          if stg.name == "$lookup"
            matches = {}
            if nested_field.depedency_field? && nested_field.field_type == "Document::Fields::DepedencyManyField"
              matches.deep_merge!({"$expr".to_sym => { "$in".to_sym => [ "$_id", "$$#{nested_field.name}_ids" ] }})
            end
            agg = aggregation.class.new
            unless matches.blank?
              agg.stages.build({name: "$match", arguments_attributes: matches.reduce([]){|arr, h| arr << { function: h[0], raw_parameter: h[1] } }})
            end
            agg.stages.append(aggregation_stages(params, field_scope))
            stg.arguments.build(function: "pipeline", raw_parameter:  agg.to_aggregation)
          end
          stg
        }
      end
      stages
    end

    def default_scopes_aggregation_stage
      scopes = options.default_scopes
      if scopes.length
        stage = Document::Grids::AggregationStage.new(name: "$match")
        res = virtual_view.run_advanced_search(scopes)
        if res.is_a?(::Mongoid::Criteria)
          res.selector.each do |k,v|
            stage.arguments.build(function: k, raw_parameter: v)
          end
        end
        stage
      end
    end

    def data(params={}, field_scope = proc{|field, grid| field})
      virtual_view.collection.aggregate(to_aggregation(params, field_scope)).first
    end


    class Options < Document::FieldOptions
      embeds_many :default_scopes, class_name: "Document::Concerns::VirtualModels::AdvancedSearch::Clause"
      accepts_nested_attributes_for :default_scopes, allow_destroy: true

      embeds_many :html_options, class_name: "Document::Grid::Options::HtmlOptions"
      accepts_nested_attributes_for :html_options, allow_destroy: true

      validate do
        default_scopes.each_with_index do |dc, i|
          unless dc.valid?
            dc.errors.each {|e| errors.import e, **e.options.merge(attribute: "default_scopes.#{i}.#{e.attribute}")}
          end
        end
      end

      class HtmlOptions < Document::FieldOptions
        attribute :name, :string
        attribute :value, :string
      end

    end

    serialize :options, Options
    serialize :aggregation, Document::Grids::Aggregation

    scope :only_container, -> { where(nested_field_id: nil) }
    scope :owned_or_default, -> (grid_owner, form) {
      # where(form_id: form.id).left_joins(:grid_owners).scoping do
      #   merge(where(document_grid_owners: { owner_type: grid_owner.class.base_class.name, owner_id: grid_owner.id }))
      #   .or(merge(where(default: true)))
      # end
      owned_by(grid_owner).or(only_default).only_form(form)
    }
    scope :owned_by, -> (grid_owner) {
      # where(form_id: form.id).left_joins(:grid_owners).scoping do
      #   where(document_grid_owners: { owner_type: grid_owner.class.base_class.name, owner_id: grid_owner.id })
      # end
      left_joins(:grid_owners)
      .where(document_grid_owners: { owner_type: grid_owner.class.base_class.name, owner_id: grid_owner.id })
    }
    scope :only_default, -> { where(default: true) }
    scope :only_form, -> (form) { where(form_id: form.id) }

    class << self

      def get_default_grid_for(grid_owner, form, **opts)
        res = owned_or_default(grid_owner, form)
        if opts[:includes]
          res = res.includes(*[:form, :sections, :fields => [ :field => [:nested_form], :nested_grid_panel => [:form, :sections, :fields], :nested_grid_list => [:form, :fields]]])
        end
        res = res.order("document_grids.default asc").first
      end

    end

  end
end