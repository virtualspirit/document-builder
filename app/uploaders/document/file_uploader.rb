module Document
  class FileUploader < Shrine

    plugin :validation_helpers, default_messages: {
      mime_type_inclusion: -> (whitelist) { I18n.t('shrine.errors.mime_type', whitelist: whitelist.join(', ')) },
      max_size: -> (max) { I18n.t('shrine.errors.max_size', max: max / 1048576.0) }
    }

    Attacher.validate do
      # validate with model validation settings
      whitelist = record.whitelist name
      max_file_size = record.max_file_size name
      validate_mime_type_inclusion whitelist unless whitelist.blank?
      validate_max_size max_file_size if max_file_size
    end

  end
end
