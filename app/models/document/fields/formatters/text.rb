module Document
  module Fields::Formatters
    class Text < Document::FieldOptions

      attribute :prefix, :string, default: ""
      attribute :suffix, :string, default: ""

      def value val
        if val.is_a?(Array)
          val.map{|s| "#{prefix}#{s}#{suffix}"}
        else
          "#{prefix}#{val}#{suffix}"
        end
      end

    end
  end
end
