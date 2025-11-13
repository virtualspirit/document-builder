module Document
  module Fields::Options
    class BooleanField < BaseOptions

      attribute :default_value, :boolean, default: false
    end
  end
end
