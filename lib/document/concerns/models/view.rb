require 'options_model'

module Document
  module Concerns
    module View

      extend ActiveSupport::Concern

      included do

        belongs_to :viewable, polymorphic: true
        has_many :columns, class_name: "Document::ViewField", foreign_key: "view_id"
        accepts_nested_attributes_for :columns, allow_destroy: true

        validates :name, presence: true

      end

      def to_virtual_model
      end

    end
  end
end

# module Document
#   module Concerns
#     module Models
#       module View

#         extend ActiveSupport::Concern

#         def self.draw fields = ::Document::Form.first.fields
#           FieldSet.draw_fields do
#             fields.each do |f|
#               if f.nested_form?
#               else
#                 field f.name, f.label
#               end
#             end
#           end
#         end

#         class FieldSet < OptionsModel::Base

#           class << self

#             def use_relative_model_naming?
#               true
#             end

#             def field_class
#               Field
#             end

#             def field_class=(klass)
#               raise ArgumentError, "#{klass} should be sub-class of #{Field}." unless klass && klass < Field

#               @field_class = klass
#             end

#             def draw_fields(constraints = {}, &block)
#               raise ArgumentError, "must provide a block" unless block_given?

#               Mapper.new(self, constraints).instance_exec(&block)

#               self
#             end

#             def registered_fields
#               @registered_fields ||= ActiveSupport::HashWithIndifferentAccess.new
#             end

#             def register_field(name, default = false, options = {}, &block)
#               raise ArgumentError, "`name` can't be blank" if name.blank?

#               attribute name, :boolean, default: default
#               registered_field[name] = field_class.new name, **options, &block
#             end

#             PERMITTED_ATTRIBUTE_CLASSES = [Symbol].freeze

#             def permitted_attribute_classes
#               PERMITTED_ATTRIBUTE_CLASSES
#             end
#           end

#         end

#         class Field
#           attr_reader :name, :label, :namespace, :order, :aggregate

#           def initialize(name, namespace: [], order: 0, **aggregate, &_block)
#             @name = name
#             @namespace = namespace
#             @order = order
#             @label = label
#             @aggregate = aggregate
#             return unless aggregate

#             # @model_name = options[:model_name]
#             # @subject = options[:subject]
#             # @action = options[:action] || name
#             # @condition_proc = options[:condition_proc]
#             # @if = options[:if]
#             # @options = options.except(:model, :model_name, :subject, :action, :condition_proc, :if)
#             # @block = _block
#           end

#           def aggregate(context, *args)

#           end

#         end

#         class AggregateField
#         end

#         class Mapper

#           def initialize(set, constraints = {})
#             @constraints = constraints
#             @constraints[:_namespace] ||= []
#             @set = set
#           end

#           def field(name, default: false, **options, &block)
#             @set.register_field name, default, @constraints.merge(options), &block
#             self
#           end

#           def group(name, constraints = {}, &block)
#             raise ArgumentError, "`name` can't be blank" if name.blank?
#             raise ArgumentError, "must provide a block" unless block_given?

#             constraints[:_namespace] ||= @constraints[:_namespace].dup
#             constraints[:_namespace] << name

#             sub_field_set_class =
#               if @set.nested_classes.key?(name)
#                 @set.nested_classes[name]
#               else
#                 klass_name = constraints[:_namespace].map { |n| n.to_s.classify }.join("::")
#                 klass = FieldSet.derive klass_name
#                 @set.embeds_one(name, anonymous_class: klass)

#                 klass
#               end

#             sub_field_set_class.draw_fields(@constraints.merge(constraints), &block)

#             self
#           end

#         end

#       end
#     end
#   end
# end