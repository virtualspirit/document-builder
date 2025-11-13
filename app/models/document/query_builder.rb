module Document
  class QueryBuilder < ApplicationRecord

    belongs_to :context, optional: true, polymorphic: true
    belongs_to :configurable, optional: true, polymorphic: true

    validates :name, presence: true

    serialize :data, Document::Concerns::VirtualModels::AdvancedSearch::Builder

    after_initialize do
      if respond_to? :data
        self.data ||= {}
      end
    end

    validate do
      unless data.valid?
        errors.add(:data, :invalid)
        data.errors.each {|e| errors.import e, **e.options.merge(attribute: "data.#{e.attribute}")}
      end
    end


  end
end
