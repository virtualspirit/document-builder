module Document
  module Grape
    module Services
      class Forms < Base

        fetch_resource_and_collection! do
          model_klass Document.form_model_class
          got_resource_callback proc { |resource|
            Document.callbacks.perform(:form_got_resource, self, resource)
          }
          query_scope do |query|
            Document.callbacks.perform(:form_query_scope, self, query)
          end
          query_includes sections: [:fields => [:nested_form]]
          resource_params_attributes do
            [
              :name, :title, :code, :step, :description, step_options: [:non_linear],
              :sections_attributes =>
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
            ]
          end
        end

        set_presenter "Document::Grape::Presenters::Form"

        resource "forms" do

          desc "Get forms"
          get "", authorize:[ [:read, :read_owned], :model_class ] do
            presenter(@forms)
          end

          desc "Create new form"
          post '', authorize:[ :create, :model_class ] do
            if @form.save
              presenter @form
            else
              standard_validation_error(details: @form.errors)
            end
          end

        end

        resource "form/:id" do

          desc "Update form"
          put '', authorize:[ [:update, :update_owned], :resource ] do
            if @form.update _resource_params
              presenter @form
            else
              standard_validation_error(details: @form.errors)
            end
          end

          desc "Delete form"
          delete '', authorize:[ [:delete, :delete_owned], :resource ] do
            @form.destroy
            presenter @form
          end

        end


      end
    end
  end
end