module Document
  module Grape
    module Presenters
      module Fields
        module Options
          class CheckboxField < Document::Grape::Presenters::Fields::Option
            expose :selections, with: Document::Grape::Presenters::Fields::Options::Choice
          end
        end
      end
    end
  end
end