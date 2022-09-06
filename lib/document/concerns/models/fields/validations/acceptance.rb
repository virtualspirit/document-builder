

module Document
  module Concerns
    module Models
      module Fields
        module Validations
          module Acceptance
            extend ActiveSupport::Concern

            included do
              attribute :acceptance, :boolean, default: false
            end

            def interpret_to(model, field_name, _accessibility, _options = {})
              super
              return unless acceptance

              model.validates field_name, acceptance: true
            end

          end
        end
      end
    end
  end
end
