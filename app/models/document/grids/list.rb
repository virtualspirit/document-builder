module Document
  module Grids
    class List < Document::Grid

      has_many :query_builders, class_name: "Document::QueryBuilder", as: :context
      has_one :panel, class_name: "Document::Grids::Panel", foreign_key: "list_id"
      has_one :default_query_builder, -> { where(default: true) }, class_name: "Document::QueryBuilder", as: :context

      accepts_nested_attributes_for :panel, reject_if: :all_blank, allow_destroy: true

      validate do
        if self.nested_field
          record.add(:nested_field, :invalid) unless nested_field.nested? && nested_field.multiple?
        end
      end

      before_save do
        if self.default
          options.build_pagination if options.pagination.blank?
          options.default_sorts.build(field: "updated_at", direction: "desc") if options.default_sorts.blank?
        end
      end

      after_create do
        if self.nested_field
          if nested_field.nested_grid_panel
            nested_field.nested_grid_panel.update(list_id: self.id)
          end
        end
      end

      def is_list?
        true
      end

      def build_default_aggregation
        aggregation.stages = []
        if nested_field
          aggregation.nested_stages = []
          if nested_field.depedency_field? && nested_field.field.type == "Document::Fields::DepedencyManyField"
            lookup = AggregationStage.new(name: "$lookup", merge: false, order: 9997, arguments_attributes: [
                { function: "from", parameter: form.collection_name },
                { function: "let", parameters_as_array: false, parameters_attributes: [
                    { function: "#{nested_field.name}_ids", parameter: "$#{nested_field.name}_ids" }
                  ]
                },
                { function: "as", parameter: nested_field.name }
              ])
          else
            lookup = AggregationStage.new(name: "$lookup", merge: false, order: 9997, arguments_attributes: [
                  { function: "from", parameter: form.collection_name },
                  { function: "localField", parameter: nested_field.depedency_field? ? "#{nested_field.name}_id" : "_id"},
                  { function: "foreignField", parameter: nested_field.depedency_field? ? "_id" : "#{nested_field.name}_id"},
                  { function: "as", parameter: nested_field.name },
            ])
          end
          aggregation.nested_stages << lookup
          project = AggregationStage.new(name: "$project", order: 9999, arguments_attributes: [{function: "#{nested_field.name}_count", parameter: 1}])
          aggregation.nested_stages << project
        end
      end

      def fields_stages field_scope= proc{|field| field}
        stages = []
        fields.each do |field|
          if field_scope.call(field)
            field.build_default_aggregation if field.default_aggregation
            if field.nested?
              unless field.multiple?
                # nested_grid = field.nested_grid_panel
                # if nested_grid
                #   nested_grid.nested_field = field
                #   nested_grid.build_default_aggregation if nested_grid.default_aggregation
                #   stages = stages + nested_grid.nested_aggregation_stages({}, field_scope)
                # end
                stages = stages + field.build_default_nested_grid_panel_aggregation
              end
            end
            stages = stages + field.aggregation.stages
          end
        end
        stages
      end

      def query_aggregation_stage params = {}
        stage = Document::Grids::AggregationStage.new(name: "$match", order: 9999)
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
            res.selector.each do |k,v|
              stage.arguments.build(function: k, raw_parameter: v)
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
        Document::Grids::AggregationStage.new(name: "$sort", order: 9999,arguments_attributes: sorts.map{|s| {function: s.field, parameter: s.direction_to_integer}})
      end

      def pagination_aggregation_stage page: nil, per_page: nil
        page ||= options.pagination.page
        per_page ||= options.pagination.per_page
        Document::Grids::AggregationStage.new(name: "$facet", order: 10000, arguments_attributes: [
          { function: 'data', parameters_attributes:
            [
              { function: "$limit", parameter: per_page.to_i * page.to_i },
              { function: "$skip", parameter: per_page.to_i * (page.to_i-1) }
            ]
          },
          { function: 'meta', parameters_attributes: [{ function: '$count', parameter: 'total' }] }
        ])
      end

      def aggregation_stages(params={}, field_scope = proc{|field| field})
        stages = super(params, field_scope)
        pagination = params[:pagination] || {}
        search = params[:search] || {}
        stages << query_aggregation_stage(search)
        stages << sort_aggregation_stage
        stages << pagination_aggregation_stage(page: params[:page], per_page: params[:per_page]) unless options.pagination.disabled
        stages
      end

      def data(params={}, field_scope = proc{|field| field})
        raw_stages = []
        if nested_field
          criteria = nil
          if nested_field.depedency_field?
            ids = params["#{nested_field.name}_ids".to_sym]
            ids = [ids].compact unless ids.is_a?(Array)
            criteria = virtual_view.in(id: ids)
          else
            criteria = virtual_view.where("#{nested_field.name}_id".to_sym => params["#{nested_field.name}_id".to_sym])
          end
          raw_stages << criteria.project(:id => "id").pipeline.filter{|p| p["$match"].present? }[0]
          aggregates = raw_stages + to_aggregation(params, field_scope)
          virtual_view.collection.aggregate(aggregates)
        else
          super(params, field_scope)
        end
      end

      class Options < Document::Grid::Options

        embeds_one :pagination, class_name: "Document::Grids::List::Pagination"
        accepts_nested_attributes_for :pagination, allow_destroy: true
        validates :pagination, presence: true

        embeds_many :default_sorts, class_name: "Document::Grids::List::Sort"
        accepts_nested_attributes_for :default_sorts, allow_destroy: true

        attribute :show_grid_panel, :boolean, default: true
        attribute :allow_search, :boolean, default: true
        attribute :allowed_search_types, :string, array: true, default: ['lazy_search']

        SEARCH_TYPES = ['lazy_search', 'heavy_search', 'configured_advanced_search', 'advanced_search']

        validate do
          if pagination
            unless pagination.valid?
              pagination.errors.each {|e| errors.import e, **e.options.merge(attribute: "pagination.#{e.attribute}")}
            end
          end
          default_sorts.each_with_index do |ds, i|
            unless ds.valid?
              ds.errors.each {|e| errors.import e, **e.options.merge(attribute: "default_sorts.#{i}.#{e.attribute}")}
            end
          end
        end

      end

      class Pagination < Document::FieldOptions

        attribute :page, :integer, default: 1
        attribute :pages, :integer, array: true, default: [25, 50, 100]
        attribute :per_page, :integer, default: 25
        attribute :disabled, :boolean, default: false
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