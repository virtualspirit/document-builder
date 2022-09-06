module Document
  module Concerns
    module VirtualModels
      module AdvancedSearch

        class Clause < Document::FieldOptions

          attribute :type, :string
          attribute :comparison_operator, :string
          attribute :field, :string
          attribute :namespace, :string
          attribute :label, :string
          attribute :placeholder, :string
          attribute :logical_operator, :string
          attribute :logical_operators, :json
          attribute :comparison_operators, :string
          attribute :ignore_blank_values, :boolean
          serialize :comparison_operators, Hash
          attribute :values

          validates_presence_of :type, :field

          embeds_many :choices, class_name: "Document::Concerns::VirtualModels::AdvancedSearch::Clause::Choice"
          accepts_nested_attributes_for :choices, reject_if: :all_blank, allow_destroy: true

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
            if(self.type)
              self.comparison_operators ||= COMPARISON_OPERATORS.select{|k,v| v[:only] ? v[:only].include?(self.type.to_sym) : v }
            end
          end

          def data_type
            DATA_TYPES[self.type.to_sym]
          end

          def cast_clause!
            case self.data_type
            when BigDecimal
              self.values = self.values.to_s unless values.is_a?(String)
            when Array
              self.values = self.values.to_s.gsub(/\s+/, "").split(",") unless values.is_a?(Array)
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
                  "#{field}": { comparison_operators.deep_symbolize_keys[comparison_operator.to_sym][:symbol] => values }
                }
              end
            end
          end

          def verified?
            verified = comparison_operators.deep_symbolize_keys.dig(self.comparison_operator.to_sym) && valid?
            if ignore_blank_values
              verified
            else
              verified && !values.blank?
            end
          end

          class Choice < Document::FieldOptions
            attribute :label, :string
            attribute :value, :string
          end

        end

      end
    end
  end
end
