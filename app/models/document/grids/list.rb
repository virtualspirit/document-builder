module Document
  module Grids
    class List < Document::Grid

      has_many :query_builders, class_name: "Document::QueryBuilder", as: :context
      has_one :panel, class_name: "Document::Grids::Panel", foreign_key: "list_id"
      has_one :default_query_builder, -> { where(default: true) }, class_name: "Document::QueryBuilder", as: :context

      accepts_nested_attributes_for :panel, reject_if: :all_blank, allow_destroy: true
      before_save do 
        if self.default
          options.build_pagination if options.pagination.blank?
          options.default_sorts.build(field: "updated_at", direction: "desc") if options.default_sorts.blank?
        end
      end

      def is_list?
        true
      end

      def build_default_aggregation
        aggregation.stages = []
        if nested_field

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
          aggregation.stages << lookup
          project = AggregationStage.new(name: "$project", order: 9999, arguments_attributes: [{function: "#{nested_field.name}_count", parameter: 1}])
          aggregation.stages << project
        end
      end

      def fields_stages field_scope= proc{|field| field}
        stages = []
        fields.each do |field|
          if field_scope.call(field)
            if field.nested?
              unless field.multiple?
                stages = stages + field.grid_panel.nested_aggregation_stages({}, field_scope)
              end
            end
            stages = stages + field.aggregation.stages
          end
        end
        stages << Document::Grids::AggregationStage.new(name: "$project", order: 9999, arguments_attributes: [{function: "created_at", parameter: 1}])
        stages << Document::Grids::AggregationStage.new(name: "$project", order: 9999, arguments_attributes: [{function: "updated_at", parameter: 1}])
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

      def pagination_aggregation_stage page: nil, per_page: nil
        page ||= options.pagination.page
        per_page ||= options.pagination.per_page
        Document::Grids::AggregationStage.new(name: "$facet", order: 10000, arguments_attributes: [          
          { function: 'data', parameters_attributes: 
            [ 
              { function: "$sort",  raw_parameter: { "_id": -1 } },
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
        stages << pagination_aggregation_stage(page: params[:page], per_page: params[:per_page]) #unless options.pagination.disabled
        stages
      end

      def to_aggregation(params={}, field_scope = proc{|field| field})
        stages = aggregation_stages(params, field_scope)
        agg = aggregation.class.new
        agg.stages.append(stages)
        # gg = [
        #   { :$addFields=>{ :employees_ids=>{"$cond"=>{"if"=>{"$ne"=>[{"$type"=>"$employees_ids"}, "array"]}, "then"=>[], "else"=>"$employees_ids"}}}},
        #   { :$addFields=>{ :attachment=>"$_attachment_url"}},
        #   { :$addFields=>{ :employees_count=>{"$size"=>"$employees_ids"}}},
        #   { :$lookup=>{ :from=>"nestedform-c2dd0763-2674-49f9-a034-98eaf652b4cc", :localField=>"_id", :foreignField=>"nested_form_id", :as=>"nested_form", :pipeline=>[{ :$project=>{ :nested_text=>1, :created_at=>1, :updated_at=>1, :version=>1}}]}},
        #   { :$lookup=>{ :from=>"document_embeds_multiple_attachments", :localField=>"_id", :foreignField=>"attachable_id", :as=>"multiple_attachment", :pipeline=>[{:$addFields=>{:"attachment"=>"$_attachment_url"}}, {:$project=>{:"_id"=>1, :"attachment"=>1, :"attachment_data"=>1}}]}},
        #   { :$lookup=>{ :from=>"form-747581dd-cb55-413e-ba98-a4150b4b0a91", :localField=>"employee_id", :foreignField=>"_id", :as=>"employee", :pipeline=>[{ :$project=>{ :employee_id=>1, :title=>1, :name=>1, :dob=>1, :start_date=>1, :address=>1, :department=>1, :phone_number=>1, :email=>1, :marital_status=>1, :salary=>1, :created_at=>1, :updated_at=>1, :version=>1}}]}},
        #   { :$lookup=>{ :from=>"fbuilder_virtual_model_submitters", :localField=>"submitter_id", :foreignField=>"_id", :as=>"submitter"}},
        #   { :$unwind=>{ :path=>"$nested_form", :preserveNullAndEmptyArrays=>true}},
        #   { :$unwind=>{ :path=>"$employee", :preserveNullAndEmptyArrays=>true}},
        #   { :$unwind=>{ :path=>"$submitter", :preserveNullAndEmptyArrays=>true}},
        #   { :$project=>{ :text=>1, :boolean=>1, :checkbox=>1, :date=>1, :date_range=>1, :datetime=>1, :datetime_range=>1, :decimal=>1, :formula=>1, :attachment=>1, :attachment_data=>1, :decimal_range=>1, :email=>1, :geolocation=>1, :geolocation_location=>1, :nested_form=>1, :integer_range=>1, :multiple_select=>1, :radio=>1, :select=>1, :signature=>1, :time=>1, :multiple_attachment=>1, :time_range=>1, :employee=>1, :employee_id=>1, :employees_ids=>1, :employees_count=>1, :multiple_nested_form_count=>1, :integer=>1, :created_at=>1, :updated_at=>1, :submitter_id=>1, :submitter=>1}},
        #   {:$match=>{:text=>[{:$eq=>"foo"}]}},
        #   { :$facet=>{ 
        #       :data=>[
        #         { :$sort=>{ "_id"=>-1 }},
        #         { :$limit=>2 },
        #         { :$skip=>1 }
        #       ], 
        #       :meta=>[
        #         { :$count=>"total" }
        #       ]
        #     }
        #   },
        #   { :$sort=>{ :updated_at=>-1 }}
        # ]
        agg.to_aggregation
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
          debugger
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

        # after_initialize do
        #   build_pagination if pagination.blank?
        #   default_sorts.build(field: "updated_at", direction: "desc") if default_sorts.blank?
        # end

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
      before_save do 
        if nested_field
          options.pagination.disabled= false
        end
      end

    end
  end
end