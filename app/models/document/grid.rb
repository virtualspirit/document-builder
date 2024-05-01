# create_table :document_grids do |t|
#   t.references :viewable, polymorphic: true
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

#     belongs_to :viewable, polymorphic: true
#     has_many :fields, class_name: "Document::Grids::Field", foreign_key: "grid_id", dependent: :destroy
#     accepts_nested_attributes_for :fields, allow_destroy: true

#     validates :name, presence: true
#     validates :type, presence: true, inclusion: { in: ['Document::Grids::List', 'Document::Grids::Panel'] }

#     def draw fields_collection = viewable.try(:fields) || [], namespace = []
#       fields_collection.each do |field|
#         self.fields << Document::Grids::Field.build(self, field, namespace)
#       end
#       self.fields
#     end

#     def virtual_view
#       if viewable
#         @virtual_view ||= viewable.to_virtual_view
#       end
#     end

#     def virtual_view!
#       if viewable
#         @virtual_view = viewable.to_virtual_view
#       end
#     end

#   end
# end

module Document
  class Grid < ApplicationRecord

    belongs_to :viewable, class_name: "Document::BareForm", foreign_key: "viewable_id"
    belongs_to :nested_field, class_name: "Document::Grids::Field", foreign_key: "nested_field_id", optional: true
    belongs_to :container, class_name: "Document::Grid", foreign_key: "container_id", optional: true
    has_many :nested_grids, class_name: "Document::Grid", foreign_key: "container_id"
    has_many :fields, -> { rank(:position) }, class_name: "Document::Grids::Field", dependent: :destroy, foreign_key: "grid_id", inverse_of: :grid, index_errors: true

    accepts_nested_attributes_for :fields, allow_destroy: true

    validates :name, presence: true
    validates :viewable, presence: true

    validate do
      if viewable
        unless viewable.class.included_modules.include?(Document::Concerns::Models::ActsAsGridViewable)
          errors.add(:viewable, :invalid)
        end
      end
    end

    before_save do
      if nested_field
        self.container = nested_field.grid
      end
    end

    after_initialize :build_default_aggregation, if: Proc.new{ aggregation.default }

    before_create :append_default_fields

    def virtual_view
      if viewable
        @virtual_view ||= viewable.to_virtual_view
      end
    end

    def is_panel?
      false
    end

    def is_list?
      false
    end

    def add_field field, namespace: [], persist: true
      if nested_field
        namespace << nested_field.name
      end
      gf = ::Document::Grids::Field.build(field, namespace)
      gf.grid = self
      gf.save if persist
      gf
    end

    def append_default_fields
      append_fields(viewable.fields)
    end

    def append_fields _fields = []
      self.fields << _fields.map{|f| add_field(f, persist: false) }
    end

    def build_default_aggregation
      aggregation
    end

    def aggregation_stages(params={}, field_scope = proc{|field| field})
      stages = fields_stages(field_scope)
      stages
    end

    def to_aggregation(params={}, field_scope = proc{|field| field})
      agg = aggregation.class.new
      agg.stages.append(aggregation_stages)
      agg.to_aggregation
    end

    def fields_stages field_scope= proc{|field| field}
      stages = []
      fields.each do |field|
        if field_scope.call(field)
          stages = stages + field.aggregation.stages
        end
      end
      stages
    end

    def nested_aggregation_stages(params={}, field_scope = proc{|field| field})
      stages = []
      if nested_field
        stages = aggregation.stages.map{|stg|
          if stg.name == "$lookup"
            agg = aggregation.class.new
            agg.stages.append(aggregation_stages(params, field_scope))
            stg.arguments.build(function: "pipeline", raw_parameter:  agg.to_aggregation)
          end
          stg
        }
      end
      stages
    end

    def default_scopes_aggregation_stage
      stage = Document::Grids::AggregationStage.new(name: "$match")
      scopes = options.default_scopes
      if scopes.length > 0
        scopes.each do |scope|
          criteria = scope.to_criteria
          criteria.each do |k,v|
            if v.is_a?(Hash)
              stage.arguments << Document::Grids::AggregationArgument.new(function: k, parameters: v.map{|s,c| {function: s, parameter: c} })
            else
              stage.arguments << Document::Grids::AggregationArgument.new(function: k, parameter: v)
            end
          end
        end
      end
      stage
    end

    def data(params={}, field_scope = proc{|field| field})
      virtual_view.collection.aggregate(to_aggregation(params, field_scope)).first
    end


    class Options < Document::FieldOptions
      embeds_many :_default_scopes, class_name: "Document::Concerns::VirtualModels::AdvancedSearch::Clause"
      accepts_nested_attributes_for :_default_scopes, allow_destroy: true
      alias :default_scopes :_default_scopes
      alias :default_scopes= :_default_scopes_attributes=

      embeds_many :_html_options, class_name: "Document::Grid::Options::HtmlOptions"
      accepts_nested_attributes_for :_html_options, allow_destroy: true

      alias :html_options :_html_options
      alias :html_options= :_html_options_attributes=

      def as_json options=nil
        hash = super(options)
        hash["html_options"]= hash.delete("_html_options")
        hash
      end

      class HtmlOptions < Document::FieldOptions
        attribute :name, :string
        attribute :value, :string
      end

    end

    serialize :options, Options
    serialize :aggregation, Document::Grids::Aggregation

  end
end