module Document
  class HashCoder < Document::Coder
    def dump(obj)
      obj&.serializable_hash || {}
    end

    def load(hash)
      return new_or_raise_decoding_error if hash.nil? || !hash.respond_to?(:to_h)

      object_class.new valid_attributes(hash)
    end
  end
end
