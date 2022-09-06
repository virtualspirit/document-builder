module Document
  module Grape
    module Services
      module Field
        class Base < Document::Grape::Services::Base

          helpers do

            def field
              field_class.find(params[:field_id])
            end

            def field_class
              Document::Field
            end

          end

          namespace "field/:field_id" do
            mount Document::Grape::Services::Field::Options
            mount Document::Grape::Services::Field::Validations
          end

        end
      end
    end
  end
end