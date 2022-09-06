module Document
  module Fields
    class TextField < Document::Field

      serialize :validations, Validations::TextField
      serialize :options, Options::TextField

      def stored_type
        :string
      end

    end
  end
end
