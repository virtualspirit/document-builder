module Document
  module Fields::Formatters
    class Date < Document::FieldOptions

      attribute :locale, :string, default: "en"
      attribute :format, :string

      FORMATS = {
        "short": "%d %b %y",
      }

      def value val
        return val if val.blank? || format.blank?
        if(val.is_a?(Array))
          val.map{|v| v.try(:strftime, format) || v}
        else
          val.try(:strftime, format) || v
        end
      end

    end
  end
end
