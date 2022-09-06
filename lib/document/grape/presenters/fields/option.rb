module Document
  module Grape
    module Presenters
      module Fields
        class Option < Base

          expose :searchable, if: lambda { |instance| !instance.is_a?(Document::NonConfigurableField) }
          expose :html_attributes, with: Document::Grape::Presenters::Fields::Options::HtmlOptions, if: lambda { |instance| !instance.is_a?(Document::NonConfigurableField) }

        end
      end
    end
  end
end