module Document
  module Grape
    module Services
      module Field
        class Options < Base

          helpers do

            def options
              field.options
            end

            def options_params
              posts.permit!
            end

            def presenter_name
              if field.attached_nested_form?
                "Document::Grape::Presenters::Fields::Options"
              else
                "Document::Grape::Presenters::Fields::Options::#{field.type.demodulize}"
              end
            end

          end

          set_presenter "Document::Grape::Presenters::Fields::Options"

          resources "options" do


            desc "Update options"
            put '' do
              options.assign_attributes(options_params)
              if options.valid? && field.save(validate: false)
                presenter options, presenter_name: presenter_name
              else
                standard_validation_error(details: options.errors)
              end
            end

          end


        end
      end
    end
  end
end