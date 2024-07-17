module Document
  module Fields::Embeds
    class TimeRange < Base

      module Core
        extend ActiveSupport::Concern

        included do
          self.searchable_fields = ["begin", "end"] if self.include?(Document::Concerns::VirtualModels::GeneralSearch)

          field :begin, type: :time
          field :end, type: :time

          validates :begin,
                    presence: true

          validates :end,
                    timeliness: {
                      after: :begin,
                      type: :time
                    },
                    allow_blank: true,
                    if: -> { read_attribute(:begin).present? }
        end

        def begin=(val)
          super(val.try(:in_time_zone)&.utc)
        end

        def end=(val)
          super(val.try(:in_time_zone)&.utc)
        end

        def begin
          super.try(:in_time_zone)&.utc
        end

        def end
          super.try(:in_time_zone)&.utc
        end

      end

      include Core

    end
  end
end
