module Document
  module Grape
    module Presenters
      module Fields
        module Options
          class TextField < Document::Grape::Presenters::Fields::Option
            expose :multiline
          end
        end
      end
    end
  end
end