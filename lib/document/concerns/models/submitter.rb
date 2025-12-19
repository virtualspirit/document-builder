module Document
  module Concerns
    module Models
      module Submitter
        extend ActiveSupport::Concern

        included do
          field :submitter_id
          field :submitter_type
        end

        def submitter
          return nil unless submitter_id
          submitter_type.constantize.find_by(id: submitter_id)
        end

        def submitter=(user)
          self.submitter_id = user&.id
          self.submitter_type = user.class.name
        end

        def self.find_by_submitter(submitter)
          where(submitter_id: submitter.id, submitter_type: submitter.class.name).first
        end

      end
    end
  end
end
