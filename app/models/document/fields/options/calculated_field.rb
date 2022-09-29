module Document
  module Fields::Options
    module CalculatedField
      extend ActiveSupport::Concern

      included do

        attribute :calculated, :boolean, default: false
        attribute :precision, :integer, default: 0
        attribute :formula

        validates :formula, presence: true, if: :calculated
        validates :precision, presence: true, if: :calculated
        validate :valid_formula?

        def valid_formula?
          str = formula
          fields = str.scan(/\{.*?\}/)
          fields.each do |f|
            str = str.gsub(/#{f}/, 1.to_s)
          end
          begin
            res = self.class.calculator.evaluate(str)
          rescue => ex
            errors.add(:formula, :invalid)
          end
        end

        def available_calculated_fields field = nil
          @available_calculated_fields ||= (field.nil?? [] : field.form.fields).select{|f| ["Document::Fields::IntegerField", "Document::Fields::DecimalField"].include?(f.type) && field.id != f.id }
        end

        def self.calculator
          @calculator ||= Keisan::Calculator.new
        end

      end

      # included do
      #   attribute :calculated, :boolean, default: false
      #   validates :formulas, presence: true, length: { minimum: 1, allow_blank: true}, if: :calculated
      #   embeds_many :formulas, class_name: "Document::Fields::Options::CalculatedField::Formula"
      #   accepts_nested_attributes_for :formulas, allow_destroy: true

      #   validate :valid_formula!

      #   def valid_formula!

      #   end

      #   def valid_brackets
      #     open_brackets_count = formulas.select{|f| f.bracket == '(' }
      #   end

      # end

      # class Formula < Document::FieldOptions

      #   OPERATORS = ["+", "-", "/", "*"]
      #   BRACKETS = ["(", ")"]

      #   self.inheritance_column = nil

      #   attribute :calculation_operator
      #   attribute :type
      #   attribute :field
      #   attribute :value, :big_decimal
      #   attribute :value_type
      #   attribute :bracket

      #   validates :type, presence: true, inclusion: { in: ["column", "literal"] }
      #   validates :calculation_operator, presence: true, inclusion: { in: OPERATORS, allow_blank: true }
      #   validates :field, presence: true, if: :column_type?
      #   validates :value, presence: true, numericality: { allow_blank: true }, if: -> (formula) { formula.percentage_number? && !formula.column_type }

      #   def column_type?
      #     type == 'column'
      #   end

      #   def percentage_number?
      #     value_type == 'percentage'
      #   end


      # end


    end
  end
end
