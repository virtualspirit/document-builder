module Document
  module Fields
    class BooleanField < Document::Field

      serialize :validations, Validations::BooleanField
      serialize :options, ::Document::NonConfigurableField

      def stored_type
        :boolean
      end

    end
  end
end
