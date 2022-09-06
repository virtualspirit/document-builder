

module Document
  class DocumentError < StandardError
  end

  class DecodingDataCorrupted < DocumentError
  end
end
