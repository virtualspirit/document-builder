module Document
  module Concerns
    module VirtualModels
      module AdvancedSearch

        class Builder < Document::FieldOptions

          #attribute :form_id, :string
          embeds_many :clauses, class_name: "Document::Concerns::VirtualModels::AdvancedSearch::Clause"
          accepts_nested_attributes_for :clauses, reject_if: :all_blank, allow_destroy: true

          validate do
            clauses.each_with_index do |clause, i|
              unless clause.valid?
                errors.add(:clauses, :invalid)
                clause.errors.each {|e| errors.import e, **e.options.merge(attribute: "clauses.#{i}.#{e.attribute}")}
              end
            end
          end

          # def form_id
          #   case Document::Form.column_for_attribute(:id).type
          #   when :uuid
          #     form_id.to_s
          #   when :integer
          #     form_id.to_s.to_i
          #   else
          #     super
          #   end
          # end

          class << self

            def build form
              #fields = []
              # form.cacher.sections.includes(:fields).each do |section|
              #   fields = fields + section.cacher.fields
              # end
              fields = form.cached_fields.sort_by(&:position_on_form)
              instance = self.new(form_id: form.id)
              clauses = clauses_template(fields)
              clauses.each do |clause|
                instance.clauses << clause
              end
              instance.clauses << Clause.new(comparison_operator: :eq, type: 'date_time', field: "created_at", label: "Created At", namespace: "")
              instance.clauses << Clause.new(comparison_operator: :eq, type: 'date_time', field: "created_at", label: "Updated At", namespace: "")
              instance
            end

            def clauses_template fields, namespace= nil
              fields.reject{|f| f.file_field? }.each_with_object([]) do |field, collection|
                nested = namespace.to_s.split(".").map(&:humanize).map(&:titleize).join("/")
                name = namespace ? "#{namespace}.#{field.name}" : field.name
                if field.attached_nested_form?
                  collection.push(*clauses_template(field.cached_nested_form.cached_fields, name))
                elsif field.depedency_field?
                  dep_form = field.options.form
                  if dep_form
                    if field.type == 'Document::Fields::DepedencyOneField'
                      collection.push(Clause.new(comparison_operator: :eq, type: field.stored_type, field: "#{name}_id", label: field.label, namespace: nested))
                    else
                      collection.push(Clause.new(comparison_operator: :eq, type: field.stored_type, field: "#{name}_ids", label: field.label, namespace: nested))
                    end
                    collection.push(*clauses_template(dep_form.cached_fields, name))
                  end
                else
                  if field.range_field?
                    from = Clause.new(comparison_operator: :eq, type: field.stored_type, field: "#{name}.from", label: field.label, namespace: nested)
                    to = Clause.new(comparison_operator: :eq, type: field.stored_type, field: "#{name}.to", label: field.label, namespace: nested)
                    collection + [from, to]
                  elsif field.type == "Document::Fields::GeolocationField"
                    collection.push(Clause.new(comparison_operator: :eq, type: field.stored_type, field: name, label: field.label, namespace: nested))
                    collection.push(Clause.new(comparison_operator: :eq, type: :string, field: "#{name}#{field.options.location_field_suffix_name}", label: field.label, namespace: nested))
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