module Document
  module Fields
    class DepedencyOneField < Document::Field

      serialize :validations, Validations::DepedencyOneField
      serialize :options, Options::DepedencyField

      def stored_type
        :string
      end

    end
  end
end
