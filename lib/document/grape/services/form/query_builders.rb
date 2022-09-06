module Document
  module Grape
    module Services
      module Form
        class QueryBuilders < Base

          fetch_resource_and_collection! do
            model_klass "Document::QueryBuilder"
            query_scope -> (query) {
              Document.callbacks.perform(:query_builder_query_scope, self, query)
            }
            got_resource_callback proc { |resource|
              Document.callbacks.perform(:query_builder_got_resource, self, resource)
            }
            resource_params_attributes do
              [
                :name,
                :context_type, :context_id
              ]
            end
          end

          helpers do

            def data_params
              posts.permit(clauses_attributes: [:ignore_blank_values, :field, :type, :comparison_operator, :logical_operator, :label, :placeholder, :namespace, choices_attributes: [:label, :value]])
            end

            def virtual_model
              @virtual_model ||= form.to_virtual_model
            end

          end

          set_presenter "Document::Grape::Presenters::QueryBuilder"

          resources "query_builders" do

            desc "Get query builder's clause templates"
            get "clause_templates", authorize:[ [:create], :model_class ] do
              presenter virtual_model.build_criteria_template(form), presenter_name: "Document::Grape::Presenters::QueryBuilderTemplate"
            end

            desc "Get query builders"
            get "", authorize:[ [:read, :read_owned], :model_class ] do
              presenter @query_builders
            end

            desc "Create new query builder"
            post '', authorize:[ [:create], :model_class ] do
              @query_builder.data.assign_attributes(data_params)
              if @query_builder.data.valid? && @query_builder.save
                presenter @query_builder
              else
                standard_validation_error(details: @query_builder.errors)
              end
            end

          end

          resource "query_builder/:id" do

            desc "Update query builder"
            put '', authorize:[ [:update, :update_owned], :resource ] do
              @query_builder.data.assign_attributes(data_params)
              if @query_builder.data.valid? && @query_builder.update(_resource_params)
                presenter @query_builder
              else
                standard_validation_error(details: @query_builder.errors)
              end
            end

            desc "Delete query builder"
            delete '', authorize:[ [:delete, :delete_owned], :resource ] do
              if @query_builder.destroy
                presenter @query_builder
              else
                standard_validation_error(details: @query_builder.errors)
              end
            end

          end


        end
      end
    end
  end
end

