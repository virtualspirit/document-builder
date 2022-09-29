# frozen_string_literal: true
module Document
  module Concerns
    module Fields
      module PresenterForCalculatedField

        extend ActiveSupport::Concern

        def available_calculated_fields
          @model.form.fields.select{|f| ["Document::Fields::IntegerField", "Document::Fields::DecimalField"].include?(f.type) }
        end

      end
    end
  end
end
