module Document
  module Fields::Embeds
    class MultipleAttachment < Base

      unless included_modules.include?(Document::Concerns::Models::ActiveStorageBridge::Attached::Macros::ActsAsUploadable)
        include Document::Concerns::Models::ActiveStorageBridge::Attached::Macros::ActsAsUploadable
      end
      acts_as_uploadable :attachment, metadata: true

      field :attachment_data, type: String

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
          fd = f.to_s + "_data"
          hash.delete(f.to_s + "_data")
          data = send(f).try(:data) || {}
          data['derivatives'] = send(f.to_s + "_derivatives") unless send(f.to_s + "_derivatives").blank?
          hash[f.to_s] = { "url": send(f.to_s + "_url"), "data": data }         
        end
        hash        
      end

    end
  end
end