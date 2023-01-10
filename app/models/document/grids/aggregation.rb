module Document
  module Grids

    class Aggregation < Document::FieldOptions

      embeds_many :stages, class_name: "Document::Grids::AggregationStage"

      def to_aggregation
        stages.sort_by(&:order).reduce({}) {|hash, stage|
          unless stage.blank?
            hash.deep_merge! stage.to_stage
          end
          hash
        }.map{|k,v| {"#{k}".to_sym => v}}
      end

    end

  end
end