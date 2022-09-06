module Document
  module Fields::Embeds
    class MultipleAttachment

      include Mongoid::Document
      include Support::Uploadable::Models::Concerns::ActsAsUploadable
      acts_as_uploadable :attachment, metadata: false, ranked: false, processing_state: false, belongs_to_owner: false

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
