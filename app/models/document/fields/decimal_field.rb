module Document
  module Fields
    class DecimalField < Document::Field

      serialize :validations, coder: Validations::DecimalField
      serialize :options, coder: Options::DecimalField

      def stored_type
        :big_decimal
      end

    end
  end
end
