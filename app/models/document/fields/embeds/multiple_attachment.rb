module Document
  module Fields::Embeds
    class MultipleAttachment

      include Mongoid::Document
      include ActsAsDefaultValue

      unless included_modules.include?(Document::Concerns::Models::ActiveStorageBridge::Attached::Macros::ActsAsUploadable)
        include Document::Concerns::Models::ActiveStorageBridge::Attached::Macros::ActsAsUploadable
      end
      acts_as_uploadable :attachment, metadata: true

      field :attachment_data, type: Hash
      field :_attachment_url, type: Hash, default: {}
      field :attachable_id, type: BSON::ObjectId
      field :attachable_type, type: String
      
      #belongs_to :attachable, polymorphic: true

      store_in collection: "document_embeds_multiple_attachments"

      after_validation do
        attacher = send("attachment_attacher") rescue nil
        if attacher
          attacher.errors.each do |err|
            errors.add :attachment, err
          end
        end
      end

      def serializable_hash options=nil
        hash = super(options)
        (self.class._uploadable_config[self.class.name] || {}).each do |f,v|
          hash[f] = self.send("_#{f}_url") rescue {}
        end
        hash        
      end

    end
  end
end