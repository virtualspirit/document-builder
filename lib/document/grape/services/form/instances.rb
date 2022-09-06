module Document
  module Grape
    module Services
      module Form
        class Instances < Base

          include Document::Grape::Helpers::Instances

          before do
            activate_step_form
          end

          set_presenter "Document::Grape::Presenters::Instance"

          resources "instances" do

            desc "Get instances"
            get "", authorize:[ [:read_instance, :read_instance_owned], :form ] do
              instances = query_scope
              if params[:search].present?
                instances = instances.lazy_search(params[:search])
              else
                if heavy_search.present?
                  instances = instances.search(heavy_search)
                else
                  if params[:advanced_search].present?
                    instances = instances.run_advanced_search advanced_search_params
                  elsif params[:simple_advanced_search].present?
                    instances = instances.run_advanced_search simple_advanced_search_params
                  else
                    instances = instances.all
                  end
                end
              end
              instances = instances.page(params[:page]).per(params[:per_page] || 25)
              presenter instances
            end

            desc "Create new instance"
            post '', authorize:[ [:create_instance, :create_instance_owned], :form ] do
              if instance.save
                presenter instance
              else
                standard_validation_error(details: instance.errors)
              end
            end

          end

          resource "instance/:id" do

            desc "Update instance"
            put '', authorize:[ [:update_instance, :update_instance_owned], :form ] do
              if instance.update instance_params
                presenter instance
              else
                standard_validation_error(details: instance.errors)
              end
            end

            desc "Delete instance"
            delete '', authorize:[ [:delete_instance, :delete_instance_owned], :form ] do
              if instance.destroy
                presenter instance
              else
                standard_validation_error(details: instance.errors)
              end
            end

          end


        end
      end
    end
  end
end
