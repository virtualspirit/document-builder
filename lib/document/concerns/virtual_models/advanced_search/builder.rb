module Document
  module Concerns
    module VirtualModels
      module AdvancedSearch

        class Builder < Document::FieldOptions

          attribute :form_id, :integer
          embeds_many :clauses, class_name: "::Document::Concerns::VirtualModels::AdvancedSearch::Clause"
          accepts_nested_attributes_for :clauses, reject_if: :all_blank, allow_destroy: true

          class << self

            def build form
              fields = []
              form.sections.each do |section|
                fields = fields + section.fields
              end
              instance = self.new(form_id: form.id)
              clauses = clauses_template(fields)
              clauses.each do |clause|
                instance.clauses << clause
              end
              instance
            end

            def clauses_template fields, namespace= nil
              fields.reject{|f| f.file_field? }.each_with_object([]) do |field, collection|
                nested = namespace.to_s.split(".").map(&:humanize).map(&:titleize).join("/")
                name = namespace ? "#{namespace}.#{field.name}" : field.name
                if field.attached_nested_form?
                  collection.push(*clauses_template(field.nested_form.fields, name))
                else
                  if field.range_field?
                    from = Clause.new(comparison_operator: :eq, type: field.stored_type, field: "#{name}.begin", label: field.label, namespace: nested)
                    to = Clause.new(comparison_operator: :eq, type: field.stored_type, field: "#{name}.end", label: field.label, namespace: nested)
                    collection + [from, to]
                  else
                    hash = {comparison_operator: :eq, type: field.stored_type, field: name, label: field.label, namespace: nested}
                    if field.has_choices_option?
                      hash[:choices_attributes] = field.options.choices.map{|choice| {label: choice.label, value: choice.value} }
                    end
                    clause = Clause.new hash
                    collection << clause
                  end
                end
              end
            end

          end

        end

      end
    end
  end
end