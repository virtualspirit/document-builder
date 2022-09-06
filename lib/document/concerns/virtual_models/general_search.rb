
module Document
  module Concerns
    module VirtualModels
      module GeneralSearch
        extend ActiveSupport::Concern

        included do

          class_attribute :searchable_fields
          self.searchable_fields = []

          include Mongoid::Search

        end

        module ClassMethods

          def lazy_search query, options={}
            full_text_search query, options
          end

          def search query, options={}
            ignore_case = options[:ignore_case]
            query = /#{query}/
            if ignore_case
              query = /#{query}/i
            end
            defined_searchable_fields = get_dot_searchable_fields
            criterias = defined_searchable_fields.each_with_object([]) do |k, collection|
              collection << { "#{k}" => query }
            end
            any_of(criterias)
          end

          def get_searchable_fields namespace = nil
            relations.each_with_object(searchable_fields.dup) do |(k,v), collection|
              if v.klass.relations.any? && (v.is_a?(Mongoid::Association::Embedded::EmbedsMany) || v.is_a?(Mongoid::Association::Embedded::EmbedsOne))
                collection << { k.to_sym => v.klass.get_searchable_fields(k) }
              end
              collection
            end
          end

          def add_as_searchable_field field
            self.searchable_fields << field
          end

          def get_dot_searchable_fields namespace=nil
            collection = relations.each_with_object(searchable_fields.dup.map!(&:to_s)) do |(k,v), collection|
              if (v.klass.relations.any? && (v.is_a?(Mongoid::Association::Embedded::EmbedsMany) || v.is_a?(Mongoid::Association::Embedded::EmbedsOne)))
                collection.push(*v.klass.get_dot_searchable_fields(k))
              end
            end
            if namespace.present?
              collection.map!{|k| "#{namespace}.#{k}" }
            end
            collection
          end

        end
      end
    end
  end
end
