module Document
  module Fields
    class DepedencyOneField < Document::Field

      serialize :validations, Validations::BooleanField
      serialize :options, Options::DepedencyOneField

      def stored_type
        :string
      end

    end
  end
end
