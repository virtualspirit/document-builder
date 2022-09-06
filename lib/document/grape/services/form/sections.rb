module Document
  module Grape
    module Services
      module Form
        class Sections < Base

          fetch_resource_and_collection! do
            model_klass "Document::Section"
            query_scope -> (query) {
              Document.callbacks.perform(:section_query_scope, self, query)
            }
            got_resource_callback proc { |resource|
              Document.callbacks.perform(:section_got_resource, self, resource)
            }
            resource_params_attributes do
              [
                :title, :headless, :id, :_destroy, :position,
                { fields_attributes:
                  [
                    :id, :_destroy, :type, :name, :label, :hint, :position, :accessibility, {options: {}}, {validations: {}},
                    build_recursive_params(recursive_key: :nested_form_attributes, permitted_attributes: [ :id, :_destroy,
                      fields_attributes: [
                        :id, :_destroy, :type, :name, :label, :hint, :position, :accessibility, {options: {}}, {validations: {}},
                        ]
                    ])
                  ]
                }
              ]
            end
          end

          set_presenter "Document::Grape::Presenters::Section"

          resources "sections" do

            desc "Get Sections"
            get "", authorize:[ [:read, :read_owned], :model_class ] do
              presenter @sections
            end

            desc "Create new section"
            post '', authorize:[ [:create], :model_class ] do
              if @section.save
                presenter @section
              else
                standard_validation_error(details: @section.errors)
              end
            end

          end

          resource "section/:id" do

            desc "Update section"
            put '', authorize:[ [:update, :update_owned], :resource ] do
              if @section.update _resource_params
                presenter @section
              else
                standard_validation_error(details: @section.errors)
              end
            end

            desc "Delete section"
            delete '', authorize:[ [:delete, :delete_owned], :resource ] do
              if @section.destroy
                presenter @section
              else
                standard_validation_error(details: @section.errors)
              end
            end

          end


        end
      end
    end
  end
end