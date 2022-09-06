begin; require 'grape'; rescue LoadError; end
begin; require 'grape_api'; rescue LoadError; end
if defined?(Grape::API) && defined?(GrapeAPI::Endpoint::Base)
  module Document
    module Grape

      module Helpers
        autoload :Shared, 'document/grape/helpers/shared'
        autoload :Instances, 'document/grape/helpers/instances'
      end

      module Services
        autoload :Base, 'document/grape/services/base'
        autoload :Forms, 'document/grape/services/forms'
        module Form
          autoload :Base, 'document/grape/services/form/base'
          autoload :Sections, 'document/grape/services/form/sections'
          autoload :Fields, 'document/grape/services/form/fields'
          autoload :Instances, 'document/grape/services/form/instances'
          autoload :Preview, 'document/grape/services/form/preview'
          autoload :QueryBuilders, 'document/grape/services/form/query_builders'
        end
        module NestedForm
          autoload :Base, 'document/grape/services/nested_form/base'
          autoload :Fields, 'document/grape/services/nested_form/fields'
        end
        module Field
          autoload :Base, 'document/grape/services/field/base'
          autoload :Options, 'document/grape/services/field/options'
          autoload :Validations, 'document/grape/services/field/validations'
        end
      end

      module Presenters
        autoload :Base, 'document/grape/presenters/base'
        autoload :Form, 'document/grape/presenters/form'
        autoload :Section, 'document/grape/presenters/section'
        autoload :Field, 'document/grape/presenters/field'
        autoload :NestedForm, 'document/grape/presenters/nested_form'
        autoload :Instance, 'document/grape/presenters/instance'
        autoload :QueryBuilder, 'document/grape/presenters/query_builder'
        autoload :QueryBuilderTemplate, 'document/grape/presenters/query_builder_template'
        autoload :Preview, 'document/grape/presenters/preview'
        autoload :VirtualField, 'document/grape/presenters/virtual_field'
        module Fields
          autoload :Base, 'document/grape/presenters/fields/base'
          autoload :Validations, 'document/grape/presenters/fields/validations'
          module Options
            autoload :Choice, 'document/grape/presenters/fields/options/choice'
            autoload :HtmlOptions, 'document/grape/presenters/fields/options/html_options'
            autoload :AttachmentField, 'document/grape/presenters/fields/options/attachment_field'
            autoload :CheckboxField, 'document/grape/presenters/fields/options/checkbox_field'
            autoload :DateField, 'document/grape/presenters/fields/options/date_field'
            autoload :DateRangeField, 'document/grape/presenters/fields/options/date_range_field'
            autoload :DatetimeField, 'document/grape/presenters/fields/options/datetime_field'
            autoload :DatetimeRangeField, 'document/grape/presenters/fields/options/datetime_range_field'
            autoload :DecimalField, 'document/grape/presenters/fields/options/decimal_field'
            autoload :DecimalRangeField, 'document/grape/presenters/fields/options/decimal_range_field'
            autoload :IntegerField, 'document/grape/presenters/fields/options/integer_field'
            autoload :IntergerRangeField, 'document/grape/presenters/fields/options/integer_range_field'
            autoload :MultipleAttachmentField, 'document/grape/presenters/fields/options/multiple_attachment_field'
            autoload :RadioField, 'document/grape/presenters/fields/options/radio_field'
            autoload :SelectField, 'document/grape/presenters/fields/options/select_field'
            autoload :TextField, 'document/grape/presenters/fields/options/text_field'
          end
          autoload :Option, 'document/grape/presenters/fields/option'
        end
      end

    end
  end

end