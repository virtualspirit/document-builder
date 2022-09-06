module Document
  module Grape
    module Helpers
      module Shared

        #should be configured on initializer config
        def current_user
          #@uploader||=  Document.form.access.uploader_proc.call(self)
        end

      end
    end
  end
end