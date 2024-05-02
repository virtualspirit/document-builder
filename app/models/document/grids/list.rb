module Document
  module Grids
    class List < Document::Grid

      has_many :query_builders, class_name: "Document::QueryBuilder", as: :context
      has_one :default_query_builder, -> { where(default: true) }, class_name: "Document::QueryBuilder", as: :context

      def is_list?
        true
      end

      def build_default_aggregation
        aggregation.stages = []
        if nested_field

          if nested_field.depedency_field? && nested_field.field.type == "Document::Fields::DepedencyManyField"
            lookup = AggregationStage.new(name: "$lookup", merge: false, order: 9997, arguments_attributes: [
                { function: "from", parameter: viewable.collection_name },
                { function: "let", parameters_as_array: false, parameters_attributes: [
                    { function: "#{nested_field.name}_ids", parameter: "$#{nested_field.name}_ids" }
                  ]
                },
                { function: "as", parameter: nested_field.name }
              ])
          else
            lookup = AggregationStage.new(name: "$lookup", merge: false, order: 9997, arguments_attributes: [
                  { function: "from", parameter: viewable.collection_name },
                  { function: "localField", parameter: nested_field.depedency_field? ? "#{nested_field.name}_id" : "_id"},
                  { function: "foreignField", parameter: nested_field.depedency_field? ? "_id" : "#{nested_field.name}_id"},
                  { function: "as", parameter: nested_field.name },
            ])
          end
          aggregation.stages << lookup
          project = AggregationStage.new(name: "$project", order: 9999, arguments_attributes: [{function: "#{nested_field.name}_count", parameter: 1}])
          aggregation.stages << project
        end
      end

      def query_aggregation_stage params = {}
        stage = Document::Grids::AggregationStage.new(name: "$match")
        if options.allow_search && params.is_a?(Hash)
          params = params.slice(*Options::SEARCH_TYPES.map(&:to_sym))
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

      def sort_aggregation_stage(sorts = {})
        sorts = sorts.reduce([]) do |arr, (key, val)|
          arr << Sort.new(field: key, direction: val)
        end
        sorts = options.default_sorts.to_a.concat(sorts)
        Document::Grids::AggregationStage.new(name: "$sort", order: 100000,arguments_attributes: sorts.map{|s| {function: s.field, parameter: s.direction_to_integer}})
      end

      def pagination_aggregation_stage page=nil, per_page=nil
        page ||= options.pagination.page
        per_page ||= options.pagination.per_page
        Document::Grids::AggregationStage.new(name: "$facet", order: 100001, arguments_attributes: [
          { function: 'meta', parameters_attributes: [{ function: '$count', parameter: 'total' }] },
          { function: 'data', parameters_attributes: [ { function: "$limit", parameter: per_page },
          { function: "$skip", parameter: per_page * (page-1) } ] }
        ])
      end

      def aggregation_stages(params={}, field_scope = proc{|field| field})
        stages = super(params, field_scope)
        page = params[:page] || options.pagination.page
        per = params[:per] || options.pagination.per_page
        search = params[:search] || {}
        stages << query_aggregation_stage(search)
        stages << sort_aggregation_stage
        stages << pagination_aggregation_stage
        stages
      end

      def to_aggregation(params={}, field_scope = proc{|field| field})
        stages = aggregation_stages(params, field_scope)
        agg = aggregation.class.new
        agg.stages.append(stages)
        agg.to_aggregation
      end

      def data(params={}, field_scope = proc{|field| field})
        raw_stages = []
        if nested_field
          criteria = nil
          if nested_field.depedency_field?
            ids = params["#{nested_field.name}_ids".to_sym]
            ids = [ids] unless ids.is_a?(Array)
            criteria = virtual_view.in(id: ids)
          else
            criteria = virtual_view.where("#{nested_field.name}_id".to_sym => params["#{nested_field.name}_id".to_sym])
          end
          raw_stages << criteria.project(:id => "id").pipeline.filter{|p| p["$match"].present? }[0]
          aggregates = raw_stages + to_aggregation(params, field_scope)
          virtual_view.collection.aggregate(aggregates).first
        else
          super(params, field_scope)
        end
      end

      class Options < Document::Grid::Options

        embeds_one :_pagination, class_name: "Document::Grids::List::Pagination"
        accepts_nested_attributes_for :_pagination, allow_destroy: true
        alias :pagination :_pagination
        alias :pagination= :_pagination_attributes=
        alias :build_pagination :build__pagination
        validates :pagination, presence: true

        embeds_many :_default_sorts, class_name: "Document::Grids::List::Sort"
        accepts_nested_attributes_for :_default_sorts, allow_destroy: true
        alias :default_sorts :_default_sorts
        alias :default_sorts= :_default_sorts_attributes=

        attribute :allow_search, :boolean, default: true
        attribute :allowed_search_types, :string, array: true, default: ['lazy_search']

        SEARCH_TYPES = ['lazy_search', 'heavy_search', 'configured_advanced_search', 'advanced_search']

        after_initialize do
          build_pagination if pagination.blank?
          default_sorts.build(field: "updated_at", direction: "desc") if default_sorts.blank?
        end

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

      serialize :options, Options

    end
  end
end