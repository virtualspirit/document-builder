require 'action_view/helpers/number_helper'

module Document
  module Fields::Formatters
    class Number < Document::FieldOptions

    include ActionView::Helpers::NumberHelper

      FORMATS = {
        'currency': 'number_to_currency',
        'readable': 'number_to_human',
        'readable_file_size': 'number_to_human_size',
        'percentage': 'number_to_percentage',
        'phone': 'number_to_phone',
        'delimiter': 'number_with_delimiter',
        'precision': 'number_with_precision',
    }

      attribute :format, :string, default: ""
      attribute :options, :string, default: {}
      serialize :options, Hash
      after_initialize do
        self.options ||= {}
      end
      # embeds_one :currency_options, class_name: "Document::Fields::Formatters::Number::CurrencyOptions"

      validates :format, inclusion: { in: FORMATS.keys, allow_blank: true }

      def value val
        return val if format.blank?
        if(val.is_a?(Array))
          val.map{|v| format_value v}
        else
          format_value val
        end
      end

      def format_value val
        case format
          when 'currency'
            return number_to_currency(val, (options || {}).deep_symbolize_keys.slice(:locale, :precision, :unit, :separator, :delimiter, :format, :strip_insignificant_zeros) )
          when 'readable'
            return number_to_human(val, (options || {}).deep_symbolize_keys.slice(:locale, :precision, :significant, :separator, :delimiter, :format, :strip_insignificant_zeros, :units) )
          when 'readable_file_size'
            return number_to_human_size(val, (options || {}).deep_symbolize_keys.slice(:locale, :precision, :significant, :separator, :delimiter, :strip_insignificant_zeros) )
          when 'percentage'
            return number_to_percentage(val, (options || {}).deep_symbolize_keys.slice(:locale, :precision, :significant, :separator, :delimiter, :format, :strip_insignificant_zeros) )
          when 'phone'
            return number_to_percentage(val, (options || {}).deep_symbolize_keys.slice(:area_code, :extension, :country_code, :delimiter, :pattern) )
          when 'delimiter'
            return number_with_delimiter(val, (options || {}).deep_symbolize_keys.slice(:locale, :separator, :delimiter_pattern) )
          when 'precision'
            return number_with_precision(val, (options || {}).deep_symbolize_keys.slice(:locale, :precision, :separator, :significant, :delimiter, :strip_insignificant_zeros) )
          else
            return val
        end
      end


      # class Options < Document::FieldOptions
      # end

      # class CurrencyOptions < Options
      #   attribute :locale, :string
      #   attribute :precision, :integer
      #   attribute :unit, :string
      #   attribute :separator, :string
      #   attribute :format, :string
      #   attribute :strip_insignificant_zeros, :boolean
      # end

      # class ReadableOptions < Options
      #   attribute :locale, :string
      #   attribute :precision, :integer
      #   attribute :significant, :boolean
      #   attribute :separator, :string
      #   attribute :unit, :string
      #   attribute :strip_insignificant_zeros, :boolean
      #   attribute :format, :string
      # end

    end
  end
end
