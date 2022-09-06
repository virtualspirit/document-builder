module Document
  module Fields
    class AttachmentFieldPresenter < FieldPresenter

      include ActionView::Helpers::UrlHelper

      def value_for_preview
        value = target.send name
        return if value.blank?
        url = "#{ENV['BASE_URL'] || 'http://localhost:3000'}"
        link_to value.original_filename, "#{url}#{value.url}"
      end

      def access_hidden?
        _name = "#{@model.name.to_s}_data"
        target.class.attribute_names.exclude?(_name) && target.class._reflections.keys.exclude?(_name) rescue false
      end

    end
  end
end
