require 'grape-entity'

module Document
  module Grape
    module Presenters
      class Instance < ::Grape::Entity

        expose :details, merge: true

        private

        def details
          object.as_json
        end

      end
    end
  end
end