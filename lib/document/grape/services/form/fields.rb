module Document
  module Grape
    module Services
      module Form
        class Fields < Base

          fetch_resource_and_collection! do
            model_klass "Document::Field"
            query_scope -> (query) {
              Document.callbacks.perform(:field_query_scope, self, query)
            }
            got_resource_callback proc { |resource|
              Document.callbacks.perform(:field_got_resource, self, resource)
            }
            resource_params_attributes do
              [
                :id, :section_id, :form_id, :_destroy, :type, :name, :label, :hint, :position, :accessibility, {options: {}}, {validations: {}},
                build_recursive_params(recursive_key: :nested_form_attributes, permitted_attributes: [ :id, :_destroy,
                  fields_attributes: [
                    :id, :_destroy, :type, :name, :label, :hint, :position, :accessibility, {options: {}}, {validations: {}},
                    ]
                ])
              ]
            end
          end

          set_presenter "Document::Grape::Presenters::Field"

          resources "fields" do

            desc "Get Fields"
            get "", authorize:[ [:read, :read_owned], :model_class ] do
              presenter @fields
            end

            desc "Create new field"
            post '', authorize:[ [:create], :model_class ] do
              if @field.save
                presenter @field
              else
                standard_validation_error(details: @field.errors)
              end
            end

          end

          resource "field/:id" do

            desc "Update field"
            put '', authorize:[ [:update, :update_owned], :resource ] do
              if @field.update _resource_params
                presenter @field
              else
                standard_validation_error(details: @field.errors)
              end
            end

            desc "Delete field"
            delete '', authorize:[ [:update, :update_owned], :resource ] do
              if @field.destroy
                presenter @field
              else
                standard_validation_error(details: @field.errors)
              end
            end

          end


        end
      end
    end
  end
end