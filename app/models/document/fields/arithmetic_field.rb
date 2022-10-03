module Document
  module Fields
    class ArithmeticField < Document::Field

      serialize :validations, Validations::ArithmeticField
      serialize :options, Options::ArithmeticField

      def stored_type
        :big_decimal
      end

      protected

        def interpret_extra_to(model, accessibility, _overrides = {})
          formula = options.formula
          calculator = options.class.calculator
          precision = options.precision
          _name = name
          model.before_validation do
            fields = formula.scan(/\{.*?\}/)
            fields.each do |f|
              field = f.gsub(/[{}]/, "")
              val = send(field) rescue 0
              formula = formula.gsub(/#{f}/, val.to_s)
            end
            val = calculator.evaluate(formula) rescue 0
            send("#{_name}=", val.to_d(precision))
          end
        end

    end
  end
end
