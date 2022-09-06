module Document
  module Grape
    module Services
      module Form
        class Base < Document::Grape::Services::Base

          helpers do

            def form
              form_class.find(params[:form_id])
            end

            def form_class
              Document.form_model_class_constant rescue error!({details: "Form model class is not Found!"}, 404)
            end

          end

          namespace "form/:form_id" do
            mount Document::Grape::Services::Form::Sections
            mount Document::Grape::Services::Form::Fields
            mount Document::Grape::Services::Form::QueryBuilders
            mount Document::Grape::Services::Form::Instances
            mount Document::Grape::Services::Form::Preview
          end

        end
      end
    end
  end
end