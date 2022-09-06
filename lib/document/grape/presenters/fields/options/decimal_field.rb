module Document
  module Grape
    module Presenters
      module Fields
        module Options
          class DecimalField < Document::Grape::Presenters::Fields::Option
            expose :step
          end
        end
      end
    end
  end
end