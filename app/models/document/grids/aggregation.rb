module Document
  module Grids

    class Aggregation < Document::FieldOptions

      embeds_many :stages, class_name: "Document::Grids::AggregationStage", index_errors: true
      accepts_nested_attributes_for :stages, reject_if: :all_blank, allow_destroy: true
      embeds_many :nested_stages, class_name: "Document::Grids::AggregationStage", index_errors: true
      accepts_nested_attributes_for :nested_stages, reject_if: :all_blank, allow_destroy: true

      validate do
        stages.each_with_index do |stage, i|
          unless stage.valid?
            errors.add(:stages, :invalid)
            stage.errors.each {|e| errors.import e, **e.options.merge(attribute: "stages.#{i}.#{e.attribute}")}
          end
        end

        nested_stages.each_with_index do |stage, i|
          unless stage.valid?
            errors.add(:nested_stages, :invalid)
            stage.errors.each {|e| errors.import e, **e.options.merge(attribute: "nested_stages.#{i}.#{e.attribute}")}
          end
        end
      end

      def to_aggregation
        # project = {}
        # arr = stages.sort_by(&:order).reduce({}) {|hash, stage|
        #   unless stage.blank?
        #     hash.deep_merge! stage.to_stage
        #   end
        #   hash
        # }
        # arr = stages.sort_by(&:order).reduce([]) {|hash, stage|
        #   unless stage.blank?
        #     if(stage.name == '$project')
        #       project.deep_merge!(stage.to_stage)
        #     else
        #       hash << stage.to_stage
        #     end
        #   end
        #   hash
        # }
        stages.sort_by(&:order).group_by{|s| s.order }.reduce([]){|ar, (order,stgs)|
          stgs.group_by(&:name).each do |name, stg|
            merged = stg.select{|d| d.merge}.reduce({}) {|hash, stage|
              unless stage.blank?
                hash.deep_merge! stage.to_stage
              end
              hash
            }
            unless merged.blank?
              ar << merged
            end
            ar.concat stg.select{|d| !d.merge}.reduce([]){ |a, stage|
              unless stage.blank?
                a << stage.to_stage
              end
            }
          end
          ar
        }
        # arr.map{|k,v| {"#{k}".to_sym => v}}
      end

    end

  end
end