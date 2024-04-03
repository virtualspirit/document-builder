module Document
  class QueryBuilder < ApplicationRecord

    validates :name, presence: true
    belongs_to :context, optional: true, polymorphic: true

    serialize :data, Document::Concerns::VirtualModels::AdvancedSearch::Builder

    after_initialize do
      if respond_to? :data
        self.data ||= {}
      end
    end


  end
end
