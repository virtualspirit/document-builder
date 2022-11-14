module Document
  module Fields::Formatters
    class DateFormatter < Document::FieldOptions

      attribute :locale, :string, default: "en"
      attribute :format, :string

      FORMATS = {
        "short": "%d %b %y",
      }

      def value val
        return val if val.blank? || format.blank?
        if(val.is_a?(Array))
          val.map{|v| v.strftime(format)}
        else
          val.strftime(format)
        end
      end

    end
  end
end
