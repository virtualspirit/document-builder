module Document
  module Grape
    module Services
      module NestedForm
        class Base < Document::Grape::Services::Base

          helpers do

            def nested_form
              nested_form_class.find(params[:nested_form_id])
            end

            def nested_form_class
              Document::NestedForm
            end


          end

          namespace "nested_form/:nested_form_id" do
            mount Document::Grape::Services::NestedForm::Fields
          end

        end
      end
    end
  end
end