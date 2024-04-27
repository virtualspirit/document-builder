module Document
  module Grids
    class List < Document::Grid

      has_many :query_builders, class_name: "Document::QueryBuilder", as: :context
      has_one :default_query_builder, -> { where(default: true) }, class_name: "Document::QueryBuilder", as: :context

      def is_list?
        true
      end

    end
  end
end