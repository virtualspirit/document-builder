module Document
  module Fields::Options
    class MultipleAttachmentField < BaseOptions
      attribute :whitelist, :string, array: true, default: []
      attribute :max_file_size, :integer, default: 10
      attribute :file_size_unit, :string, default: "megabytes"

      def max_file_size_in_bytes
        if max_file_size.to_f > 0
          return  case file_size_unit
                  when 'bytes'
                    max_file_size.to_f
                  when 'kilobytes'
                    max_file_size.to_f * 1024
                  when 'megabytes'
                    (max_file_size.to_f * 1024) * 1024
                  else
                    nil
                  end
        end
      end

    end
  end
end
