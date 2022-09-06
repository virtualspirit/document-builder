
require_relative "./advanced_search/query"
require_relative "./advanced_search/builder"
require_relative "./advanced_search/clause"

module Document
  module Concerns
    module VirtualModels
      module AdvancedSearch
        extend ActiveSupport::Concern

        module ClassMethods

          def build_criteria_template form
            Builder.build(form)
          end

          def run_advanced_search clauses
            Query.build(virtual_model: self, clauses: clauses).run
          end

        end
      end
    end
  end
end
