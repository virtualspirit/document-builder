module Document
  module Grape
    module Services
      module Form
        class Preview < Base

          include Document::Grape::Helpers::Instances

          set_presenter "Document::Grape::Presenters::Preview"

          resources "preview" do

            desc "New instance"
            get '', authorize:[ [:create_instance, :create_instance_owned], :form ]  do
              presenter(form, { instance: instance })
            end

            desc "Edit instance"
            get ':id', authorize:[ [:update_instance, :update_instance_owned], :form ] do
              presenter(form, instance: instance)
            end

          end


        end
      end
    end
  end
end
