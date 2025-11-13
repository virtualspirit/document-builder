# create_table :document_grids do |t|
#   t.references :viewable, polymorphic: true
#   t.string :name
#   t.text :options
#   t.integer :order
#   t.string :type
#   t.text :configuration
#   t.boolean :default, default: false
#   t.timestamps
# end

module Document
  class Grid < ApplicationRecord

    belongs_to :viewable, polymorphic: true
    has_many :fields, class_name: "Document::Grids::Field", foreign_key: "view_id"
    accepts_nested_attributes_for :fields, allow_destroy: true

    validates :name, presence: true
    validates :type, presence: true, inclusion: { in: ['Document::Grids::Table', 'Document::Grids::Panel'] }

    def draw fields_collection = viewable.try(:fields) || [], _fields = []
      fields_collection.each do |field|
        if field.nested_form.present? || field.is_a?(Document::Fields::DepedencyManyField) || field.is_a?(Document::Fields::DepedencyOneField)
          _fields << Document::Grids::Field::NestedColumn.build(self, field)
        else
          _fields << Document::Grids::Field::Column.build(self, field)
        end
      end
      _fields
    end

    def default_aggregation_stages
      configuration.aggregation.try(:stages) || []
    end

    def fields_aggregation_stages _fields = fields
      # _fields.to_a.reduce([]) {|sum, field| sum << field.to_aggregation }.flatten.reduce({}, :deep_merge)
      _fields = draw
      _fields.to_a.map{|f| f.aggregation_stages }.flatten
    end

    def pagination_aggregation_stage page=nil, per_page=nil
      page ||= configuration.pagination.page
      per_page ||= configuration.pagination.per_page
      Document::Grids::AggregationStage.new(name: "$facet", order: 100001, arguments_attributes: [
        { function: 'meta', parameters_attributes: [{ function: '$count', parameter: 'total' }] },
        { function: 'data', parameters_attributes: [ { function: "$limit", parameter: per_page }, { function: "$skip", parameter: per_page * (page-1) } ] }
      ])
    end

    def sort_aggregation_stage(sorts = {})
      sorts = sorts.reduce([]) do |arr, (key, val)|
        arr << Sort.new(field: key, direction: val)
      end
      sorts = configuration.default_sorts.to_a.concat(sorts)
      Document::Grids::AggregationStage.new(name: "$sort", order: 100000,arguments_attributes: sorts.map{|s| {function: s.field, argument: s.direction_to_integer}})
    end

    def initial_scopes_aggregation_stage
      stage = Document::Grids::AggregationStage.new(name: "$match")
      scopes = configuration.initial_scopes
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

    def query_aggregation_stage params = {}
      stage = Document::Grids::AggregationStage.new(name: "$match")
      if configuration.allow_search && params.is_a?(Hash)
        params = params.slice(*Configuration::SEARCH_TYPES.map(&:to_sym))
        res = nil
        if params[:lazy_search]
          res = virtual_view.lazy_search(params[:lazy_search].to_s)
        else
          if params[:heavy_search]
            res = virtual_view.heavy_search(params[:heavy_search].to_s)
          else
            if params[:configured_advanced_search]
              res = virtual_view.run_advanced_search(params[:configured_advanced_search])
            else
              if params[:advanced_search]
                res = virtual_view.run_advanced_search(params[:advanced_search])
              end
            end
          end
        end
        if res.is_a?(::Mongoid::Criteria)
          res = res.project(:id => "id").pipeline.filter{|p| p["$match"].present? }[0]
          if res && res["$match"].is_a?(Hash)
            res["$match"].each do |k,v|
              if v.is_a?(Hash)
                stage.arguments << Document::Grids::AggregationArgument.new(function: k, parameters: v.map{|s,c| {function: s, parameter: c} })
              else
                stage.arguments << Document::Grids::AggregationArgument.new(function: k, parameter: v)
              end
            end
          end
        end
      end
      stage
    end

    def virtual_view
      if viewable
        @virtual_view ||= viewable.to_virtual_view
      end
    end

    def virtual_view!
      if viewable
        @virtual_view = viewable.to_virtual_view
      end
    end

    def to_aggregation params={}
      page = params[:page] || configuration.pagination.page
      per = params[:per] || configuration.pagination.per_page
      search = params[:search] || {}
      stages = [
        default_aggregation_stages,
        initial_scopes_aggregation_stage,
        query_aggregation_stage(search),
        fields_aggregation_stages,
        sort_aggregation_stage,
        pagination_aggregation_stage
      ].flatten.compact_blank
      aggregation = Document::Grids::Aggregation.new
      aggregation.stages.append(stages)
      aggregation.to_aggregation
    end

    def data params={}
      virtual_view.collection.aggregate(to_aggregation(params))
    end

    class Configuration < Document::FieldOptions

      embeds_one :aggregation, class_name: 'Document::Grids::Aggregation'
      accepts_nested_attributes_for :aggregation, allow_destroy: true

      embeds_many :initial_scopes, class_name: "Document::Concerns::VirtualModels::AdvancedSearch::Clause"
      accepts_nested_attributes_for :initial_scopes, allow_destroy: true

      embeds_many :default_scopes, class_name: "Document::Concerns::VirtualModels::AdvancedSearch::Clause"
      accepts_nested_attributes_for :default_scopes, allow_destroy: true

      embeds_one :query_builder, class_name: "Document::Concerns::VirtualModels::AdvancedSearch::Builder"
      accepts_nested_attributes_for :query_builder, allow_destroy: true

      embeds_one :pagination, class_name: "Document::Grid::Pagination"
      accepts_nested_attributes_for :pagination, allow_destroy: true
      validates :pagination, presence: true

      embeds_many :default_sorts, class_name: "Document::Grid::Sort"
      accepts_nested_attributes_for :default_sorts, allow_destroy: true
      validates :sort, presence: true

      attribute :allow_search, :boolean, default: true
      attribute :allowed_search_types, :string, array: true, default: ['lazy_search']

      SEARCH_TYPES = ['lazy_search', 'heavy_search', 'configured_advanced_search', 'advanced_search']

      validates :query_builder, presence: true, if: -> (res) { res.allowed_search_types.include?('configured_advanced_search') }

      after_initialize do
        build_pagination if pagination.blank?
      end

    end

    class Options < Document::FieldOptions
    end

    class Pagination < Document::FieldOptions
      attribute :page, :integer, default: 1
      attribute :pages, :integer, array: true, default: [25, 50, 100]
      attribute :per_page, :integer, default: 25
      validates :page, presence: true, numericality: { greater_than: 0, only_integer: true, allow_blank: true }
      validates :per_page, presence: true, numericality: { greater_than: 0, only_integer: true, allow_blank: true }
    end

    class Sort < Document::FieldOptions
      attribute :field
      attribute :direction
      validates :direction, inclusion: { in: ['asc', 'desc'], allow_blank: true }

      def to_sort
        { "#{field}": direction == 'asc' ? 1 : -1 }
      end

      def direction_to_integer
        direction.to_s == 'asc' ? 1 : -1
      end

    end

    serialize :configuration, Document::Grid::Configuration
    serialize :options, Document::Grid::Options

  end
end