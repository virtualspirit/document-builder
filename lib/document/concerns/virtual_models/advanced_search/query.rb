module Document
  module Concerns
    module VirtualModels
      module AdvancedSearch

        class Query

          attr_accessor :clauses, :virtual_model

          def initialize clauses: [], virtual_model: nil
            self.virtual_model = virtual_model
            self.clauses = clauses
          end

          def run
            model = virtual_model
            clauses.select(&:verified?).each do |clause|
              logical_operator = clause.logical_operator || :where
              model = model.send(logical_operator, clause.to_criteria)
            end
            model
          end

          class << self

            def build virtual_model:, clauses: []
              clauses = clauses.map{|clause| Clause.new(clause) }
              self.new(virtual_model: virtual_model, clauses: clauses)
            end

          end

        end

      end
    end
  end
end