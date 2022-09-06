module Document
  module Grape
    module Presenters
      module Fields
        module Options
          class SelectField < Document::Grape::Presenters::Fields::Option
            expose :selections, with: Document::Grape::Presenters::Fields::Options::Choice
            expose :strict
          end
        end
      end
    end
  end
end