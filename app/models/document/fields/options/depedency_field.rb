module Document
  module Fields::Options
    class DepedencyField < BaseOptions

      attribute :document_form_id, :string
      attribute :display_value_field, :string, default: "_id"
      attribute :display_value_fields, :string, array: true, default: ["_id"]
      embeds_many :clauses, class_name: "Document::Fields::Options::DepedencyField::Clause"
      accepts_nested_attributes_for :clauses, allow_destroy: true

      validates :document_form_id, presence: true
      validates :display_value_field, presence: true, inclusion: { in: -> (dof) { dof.fields } }, if: :form
      validate do
        unless form
          errors.add(:document_form_id, :invalid)
        end
      end

      attr_accessor :_append_choices_as_json

      def as_json options=nil
        if _append_choices_as_json
          super(options).merge({choices: choices})
        else
          super(options)
        end
      end

      def append_choices_as_json
        self._append_choices_as_json = true
      end

      def virtual_model
        @virtual_model ||= form.try(:to_virtual_view)
      end

      def form
        @form ||= Document.form_model_class_constant.includes(:fields).find_by_id(document_form_id_value)
      end

      def document_form_id_value
        case Document::Form.column_for_attribute(:id).type
        when :uuid
          document_form_id.to_s
        when :integer
          document_for_id.to_s.to_i
        else
          document_form_id
        end
      end

      def clause_templates
        @clause_templates ||= virtual_model.try(:build_criteria_template, form) rescue []
      end

      def fields
        (clause_templates.try(:clauses) || []).map{|cf| cf.field }
      end

      def collection
        return @collection if @collection
        if virtual_model
          @collection = virtual_model.where("_id.ne": nil)
          clauses.select(&:verified?).each do |clause|
            logical_operator = clause.logical_operator || :where
            @collection = @collection.send(logical_operator, clause.to_criteria)
          end
          projection = ([display_value_field] + display_value_fields).uniq.select{|f| f != '_id'}.reduce({}) { |p,f|
            p[f] = 1
            p
          }
          @collection.project(p)
        end
        @collection || []
      end

      def choices
        collection.map{|c| { value: c.id.to_s, label: c.send(display_value_field).to_s } }
      end

      class Clause < Document::FieldOptions

        attribute :type, :string, default: ""
        attribute :comparison_operator, :string
        attribute :field, :string
        attribute :namespace, :string
        attribute :logical_operator, :string
        attribute :logical_operators, :json
        attribute :comparison_operators, :string, default: {}
        # attribute :ignore_blank_values, :boolean
        serialize :comparison_operators, Hash
        attribute :values
        validates :type, presence: true
        validates :field, presence: true
        validates :comparison_operator, presence: true, inclusion: { in: -> (clause){ clause.comparison_operators } }

        DATA_TYPES = {
          :integer => Integer,
          :float => Float,
          :big_decimal => BigDecimal,
          :boolean => ActiveModel::Type::Boolean,
          :date => Date,
          :date_time => DateTime,
          :object_id => BSON::ObjectId,
          :array => Array,
          :hash => Hash,
          :binary => BSON::Binary,
          :range => Range,
          :set => Set,
          :string => String,
          :symbol => Symbol,
          :time => Time,
          :time_with_zone => ActiveSupport::TimeWithZone
        }

        COMPARISON_OPERATORS = {
          eq: { symbol: "$eq", name: "Equal" },
          like: { symbol: "$eq", name: "Like", only: [:string] },
          ilike: { symbol: "$eq", name: "Ilike", only: [:string] },
          gt: { symbol: "$gt", name: "Greater Than", only: [:integer, :big_decimal, :float, :time, :date, :date_time] },
          gte: { symbol: "$gt", name: "Greater Than or Equal", only: [:integer, :big_decimal, :float, :time, :date, :date_time]},
          lt: { symbol: "$lt", name: "Less Than", only: [:integer, :big_decimal, :float, :time, :date, :date_time]},
          lte: { symbol: "$lt", name: "Less Than or Equal", only: [:integer, :big_decimal, :float, :time, :date, :date_time]},
          in: { symbol: "$in", name: "Inclusion" },
          nin: { symbol: "$nin", name: "Exclusion"},
          ne: { symbol: "$ne", name: "Not Equal"},
        }

        LOGICAL_OPERATORS = {
          and: { symbol: "$and", name: "And" },
          or: { symbol: "$or", name: "Or" },
        }

        after_initialize do
          self.logical_operators ||= LOGICAL_OPERATORS
          if(self.type && self.comparison_operators.blank?)
            self.comparison_operators = COMPARISON_OPERATORS.select{|k,v| v[:only] ? v[:only].include?(self.type.to_s.to_sym) : v }
          end
        end

        def data_type
          DATA_TYPES[self.type.to_s.to_sym]
        end

        def cast_clause!
          case self.data_type
          when BigDecimal
            self.values = self.values.to_s unless values.is_a?(String)
          when Array
            unless self.values.is_a?(Array)
              self.values = self.values.to_s.gsub(/\s+/, "").split(",") unless values.is_a?(Array)
            end
          when ActiveModel::Type::Boolean
            self.values = ActiveModel::Type::Boolean.new.cast(self.values)
          end
        end

        def to_criteria
          cast_clause!
          if verified?
            if [:ilike, :like].include?(comparison_operator.to_sym)
              val = comparison_operator.to_sym == :like ? /#{values}/ : /#{values}/i
              {
                "#{field}": val
              }
            else
              {
                "#{field}": { comparison_operators.deep_symbolize_keys[comparison_operator.to_sym][:symbol] => cast_value! }
              }
            end
          end
        end

        def verified?
          verified = comparison_operators.deep_symbolize_keys.dig(self.comparison_operator.to_sym) && valid?
          # if ignore_blank_values
          #   verified
          # else
          #   verified && !values.blank?
          # end
        end

        def cast_value!
          case data_type.try(:name)
          when "Integer"
            Integer(values)
          when "Float"
            Float(values)
          when "BigDecimal"
            BigDecimal(values)
          when "ActiveModel::Type::Boolean"
            ActiveModel::Type::Boolean.new.cast(values)
          when "Date"
            Date.parse(values.to_s)
          when "DateTime"
            DateTime.parse(values.to_s)
          when "BSON::ObjectId"
            BSON::ObjectId(values.to_s)
          when "Array"
            JSON.parse values
          when "Hash"
            JSON.parse values
          when "Time"
            Time.parse values.to_s
          else
            values
          end
        rescue => e
          nil
        end

      end

      class SimpleView < Document::FieldOptions
      end

      class AdvancedView < Document::FieldOptions
      end

    end
  end
end
