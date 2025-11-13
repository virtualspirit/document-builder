module Document
  module Grape
    module Services
      module NestedForm
        class Fields < Base

          fetch_resource_and_collection! do
            model_klass "Document::Field"
            query_scope -> (query) {
              query.where(nested_form: nested_form).rank(:position)
            }
            got_resource_callback proc { |resource|
              resource.nested_form = nested_form
            }
            resource_params_attributes do
              [
                :id, :section_id, :_destroy, :type, :name, :label, :hint, :position, :accessibility, {options: {}}, {validations: {}}
              ]
            end
          end

          set_presenter "Document::Grape::Presenters::Field"

          resources "fields" do

            desc "Get Fields"
            get "" do
              presenter @fields
            end

            desc "Create new field"
            post '' do
              if @field.save
                presenter @field
              else
                standard_validation_error(details: @field.errors)
              end
            end

          end

          resource "field/:id" do

            desc "Update field"
            put '' do
              if @field.update _resource_params
                presenter @field
              else
                standard_validation_error(details: @field.errors)
              end
            end

            desc "Delete field"
            delete '' do
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