module Document
  module Grids

    class Aggregation < Document::FieldOptions

      embeds_many :stages, class_name: "Document::Grids::AggregationStage"

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