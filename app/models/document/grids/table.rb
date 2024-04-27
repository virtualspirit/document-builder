module Document
  module Grids
    class Table < Document::Grid

      has_one :query_builder, class_name: "Document::QueryBuilder", as: :context

      def default_aggregation_stages
        configuration.aggregation.try(:stages) || []
      end

      def fields_aggregation_stages _fields_ = fields
        _fields_.to_a.map{|f| f.aggregation_stages }.flatten
      end

      def pagination_aggregation_stage page=nil, per_page=nil
        page ||= configuration.pagination.page
        per_page ||= configuration.pagination.per_page
        Document::Grids::AggregationStage.new(name: "$facet", order: 100001, arguments_attributes: [
          { function: 'meta', parameters_attributes: [{ function: '$count', parameter: 'total' }] },
          { function: 'data', parameters_attributes: [ { function: "$limit", parameter: per_page },
          { function: "$skip", parameter: per_page * (page-1) } ] }
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

      def to_aggregation(params={}, fields_scope = proc{|fields| fields})
        page = params[:page] || configuration.pagination.page
        per = params[:per] || configuration.pagination.per_page
        search = params[:search] || {}
        stages = [
          default_aggregation_stages,
          initial_scopes_aggregation_stage,
          query_aggregation_stage(search),
          fields_aggregation_stages(fields_scope.call(fields)),
          sort_aggregation_stage,
          pagination_aggregation_stage
        ].flatten.compact_blank
        aggregation = Document::Grids::Aggregation.new
        aggregation.stages.append(stages)
        aggregation.to_aggregation
      end

      def data(params={}, fields_scope = proc{|fields| fields})
        virtual_view.collection.aggregate(to_aggregation(params, fields_scope))
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

        embeds_one :pagination, class_name: "Document::Grids::List::Pagination"
        accepts_nested_attributes_for :pagination, allow_destroy: true
        validates :pagination, presence: true

        embeds_many :default_sorts, class_name: "Document::Grids::List::Sort"
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

      serialize :configuration, Configuration
      serialize :options, Options

      after_initialize do
        if respond_to? :configuration
          self.configuration ||= {}
        end
        if respond_to? :options
          self.options ||= {}
        end
      end

    end
  end
end