module Document
  module Fields
    class TextField < Document::Field

      serialize :validations, coder: Validations::TextField
      serialize :options, coder: Options::TextField

      def stored_type
        :string
      end

    end
  end
end
