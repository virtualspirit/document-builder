module Document
  module Grape
    module Services
      class Base < ::GrapeAPI::Endpoint::Base

        format :json

        helpers Document::Grape::Helpers::Shared

        namespace :document do
          mount Document::Grape::Services::Forms
          mount Document::Grape::Services::Form::Base
          mount Document::Grape::Services::NestedForm::Base
          mount Document::Grape::Services::Field::Base
        end

      end
    end
  end
end
