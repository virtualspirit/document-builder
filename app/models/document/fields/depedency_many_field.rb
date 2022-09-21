module Document
  module Fields
    class DepedencyManyField < Document::Field

      serialize :validations, Validations::DepedencyManyField
      serialize :options, Options::DepedencyField

      def stored_type
        :array
      end

    end
  end
end
