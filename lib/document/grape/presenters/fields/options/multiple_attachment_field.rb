module Document
  module Grape
    module Presenters
      module Fields
        module Options
          class MultipleAttachmentField < Document::Grape::Presenters::Fields::Option
            expose :whitelist
            expose :max_file_size
            expose :max_file_size_unit
          end
        end
      end
    end
  end
end