module Document
  module Grape
    module Presenters
      module Fields
        class Validations < Base

          expose :details, merge: true

          private

            def details
              object.as_json
            end

        end
      end
    end
  end
end