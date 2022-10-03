module Document
  module Fields
    class SignatureField < Document::Field

      serialize :validations, Validations::SignatureField
      serialize :options, Options::SignatureField

      def stored_type
        :string
      end

    end
  end
end
