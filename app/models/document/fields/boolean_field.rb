module Document
  module Fields
    class BooleanField < Document::Field

      serialize :validations, Validations::BooleanField
      serialize :options, Options::BooleanField

      def stored_type
        :boolean
      end

    end
  end
end
