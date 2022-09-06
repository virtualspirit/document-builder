module Document
  module Grape
    module Presenters
      module Fields
        module Options
          class Choice < Document::Grape::Presenters::Fields::Base
            expose :label
            expose :value
          end
        end
      end
    end
  end
end