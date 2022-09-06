module Document
  module Fields
    class MultipleAttachmentFieldPresenter < FieldPresenter

      include ActionView::Helpers::UrlHelper

      def value_for_preview
        value = target.send name
        return if value.blank?
        url = "#{ENV['BASE_URL'] || 'http://localhost:3000'}"
        value.map do |v|
          link_to v.attachment.original_filename, "#{url}#{v.attachment.url}"
        end.join("</br>").html_safe
      end

    end
  end
end
