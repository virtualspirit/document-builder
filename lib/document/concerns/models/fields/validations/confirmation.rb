
module Document
  module Concerns
    module Models
      module Fields
        module Validations
          module Confirmation
          
            extend ActiveSupport::Concern
        
            included do
              attribute :confirmation, :boolean, default: false
            end
        
            def interpret_to(model, field_name, _accessibility, _options = {})
              super
              return unless confirmation
        
              model.validates field_name, confirmation: true
            end

          end
        end
      end
    end
  end
end
