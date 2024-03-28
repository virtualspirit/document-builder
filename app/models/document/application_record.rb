module Document
  class ApplicationRecord < ActiveRecord::Base

    self.abstract_class = true

    include Document::Concerns::Models::ActsAsDefaultValue
    include Document::Concerns::Models::EnumAttributeLocalizable

  end
end
