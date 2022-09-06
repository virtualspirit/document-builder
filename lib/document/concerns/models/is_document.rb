module Document
  module Concerns
    module Models
      module IsDocument
        extend ActiveSupport::Concern

        included do
          belongs_to :form, class_name: "Document::Form", foreign_key: "form_id", optional: true

          serialize :fields

          attr_accessor :temp_fields

        end

        def assign_fields params={}
          self.temp_fields = {}
          if fields
            self.temp_fields = self.fields
          end
          self.temp_fields = self.temp_fields.deep_merge params
        end

        def virtual_form_model
          @_instance_model ||= if form
            form.to_virtual_model
          end
        end

        def virtual_form_instance
          @_instance ||= if form
            virtual_form_model.new(temp_fields || fields || {})
            end
        end

        def virtual_fields
          @_fields ||= if form
              form.sections.map{|section| section.virtual_fields(virtual_form_instance) }.flatten
            end
        end

        def validate_fields
          begin
            self.class.transaction do
              if virtual_form_instance
                if virtual_form_instance.valid?
                  self.fields= virtual_form_instance.serializable_hash
                else
                  self.errors.merge! virtual_form_instance.errors
                  raise ActiveRecord::Rollback
                end
              end
            end
          rescue ActiveRecord::Rollback => e
            self.errors.merge! virtual_form_instance.errors
          end
        end

      end
    end
  end
end
