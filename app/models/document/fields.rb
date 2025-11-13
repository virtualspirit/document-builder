module Document
  module Fields

    %w[
      text boolean decimal integer
      date datetime time
      radio checkbox
      select multiple_select
      integer_range decimal_range date_range datetime_range time_range
      nested_form multiple_nested_form attachment multiple_attachment
      depedency_one depedency_many arithmetic signature geolocation email
    ].each do |type|
      require_dependency "document/fields/#{type}_field"
    end

    MAP = ::Hash[*Field.descendants.map { |f| [f.type_key, f] }.flatten]

  end
end
