require 'action_view/helpers'

module Document
  module Rails
    module FormHelpers

      module SignatureFieldHelper
        include ActionView::Helpers::TagHelper

        def signature_canvas container_class="signature-field-container"
          content_tag(:canvas, nil, class: 'signature-field-canvas', data: { 'container-class': container_class })
        end

        def hidden_signature_field(attribute, options = {class: 'signature-field-hidden'})
          options = options.merge({class: 'signature-field-hidden'})
          hidden_field(attribute.to_sym, options)
        end

        def signature_field(attribute, options = {})
          tags = []
          tags << signature_canvas
          tags << hidden_signature_field(attribute, options)
          content_tag :div, tags.join(' ').html_safe, class: "signature-field-container"
        end
      end

      def self.included(_base)
        ActionView::Helpers::FormBuilder.instance_eval do
          include SignatureFieldHelper
        end
      end

    end
  end
end

ActionView::Base.send :include, Document::Rails::FormHelpers