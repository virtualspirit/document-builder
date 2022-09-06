module Document
  module Grape
    module Presenters
      module Fields
        module Options
          class HtmlOptions < Document::Grape::Presenters::Fields::Base
            expose :name
            expose :value
          end
        end
      end
    end
  end
end