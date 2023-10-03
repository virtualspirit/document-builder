module Document
  module Fields::Embeds
    class MultipleAttachment

      include Mongoid::Document
      unless included_modules.include?(Document::Concerns::Models::ActiveStorageBridge::Attached::Macros::ActsAsUploadable)
        include Document::Concerns::Models::ActiveStorageBridge::Attached::Macros::ActsAsUploadable
      end
      acts_as_uploadable name, metadata: true

      field :attachment_data, type: String

      after_validation do
        attacher = send("attachment_attacher") rescue nil
        if attacher
          attacher.errors.each do |err|
            errors.add :attachment, err
          end
        end
      end

    end
  end
end
