module Document
  module Grids

    class AggregationStage < Document::FieldOptions

      attribute :name
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


    end

  end
end