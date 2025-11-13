module Document
  module Concerns
    module Models
      module ActsAsViewable
        extend ActiveSupport::Concern

        included do
          has_many :grids, class_name: "Document::Grid", as: :viewable
        end

        def to_virtual_view
          raise ArgumentError, "#{self} must return a #{::Document::VirtualModel}'s subclass"
        end

      end
    end
  end
end
