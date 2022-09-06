module Document
  module Grape
    module Services
      module Field
        class Validations < Base

          helpers do

            def validations
              field.validations
            end

            def validations_params
              posts.permit!
            end

          end

          set_presenter "Document::Grape::Presenters::Fields::Validations"

          resources "validations" do


            desc "Update validations"
            put '' do
              validations.assign_attributes(validations_params)
              if validations.valid? && field.save(validate: false)
                presenter validations
              else
                standard_validation_error(details: validations.errors)
              end
            end

          end


        end
      end
    end
  end
end