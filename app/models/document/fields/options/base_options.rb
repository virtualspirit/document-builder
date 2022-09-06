module Document
  module Fields::Options
    class BaseOptions < Document::FieldOptions

      embeds_many :html_options, class_name: "Document::Fields::Options::BaseOptions::HtmlOptions"
      accepts_nested_attributes_for :html_options, reject_if: :all_blank, allow_destroy: true
      alias_method :html_attributes=, :html_options_attributes=
      alias_method :html_attributes, :html_options

      attribute :searchable, :boolean, default: false
      #Ex:- :default =>''

      class HtmlOptions < Document::FieldOptions

        attribute :name, :string, default: ""
        attribute :value, :string, default: ""

      end

    end
  end
end
