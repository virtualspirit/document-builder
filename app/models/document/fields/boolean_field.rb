module Document
  module Fields
    class BooleanField < Document::Field

      serialize :validations, coder: Validations::BooleanField
      serialize :options, coder: ::Document::NonConfigurableField

      def stored_type
        :boolean
      end

    end
  end
end
