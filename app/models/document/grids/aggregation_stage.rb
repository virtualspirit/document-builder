module Document
  module Grids

    class AggregationStage < Document::FieldOptions

      attribute :name
      attribute :id, :string
      attribute :order, :integer, default: 0
      attribute :merge, :boolean, default: true

      validates :name, presence: true, inclusion: { in: [ '$facet', '$match', '$group', '$project', '$sort', '$skip', '$limit', '$unwind', "$lookup", '$addFields'], allow_blank: true }

      embeds_many :arguments, class_name: 'Document::Grids::AggregationArgument'
      accepts_nested_attributes_for :arguments, allow_destroy: true

      def to_stage
        {
          "#{name}": to_arguments
        }
      end

      def to_arguments
        arguments.reduce({}) {|hash, args| hash.deep_merge! args.to_argument }
      end

      def blank?
        to_stage["#{name}".to_sym].blank? && to_stage["#{name}"].blank?
      end

      class AddFields < AggregationStage

      end

      class Bucket < AggregationStage

      end

      class Count < AggregationStage

      end

      class Group < AggregationStage

      end

      class Limit < AggregationStage

      end

      class Facet < AggregationStage

      end

      class Match < AggregationStage

      end

      class Lookup < AggregationStage

      end

      class Merge < AggregationStage

      end

      class Sort < AggregationStage

      end

      class Skip < AggregationStage

      end

      class Unwind < AggregationStage

      end


    end

  end
end