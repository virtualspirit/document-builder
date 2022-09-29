module Document
  module Fields::Options
    class ArithmeticField < BaseOptions

      attribute :precision, :integer, default: 0
      attribute :formula
      attribute :order, :integer, default: 0

      validates :formula, presence: true
      validates :precision, presence: true, numericality: { only_integer: true, allow_blank: true, greater_than_or_equal_to: 0 }
      validates :order, numericality: { only_integer: true, allow_blank: true }
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
  end
end
