module Document
  module Fields
    class TimeFieldPresenter < FieldPresenter

      def value
        super&.in_time_zone
      end

      def value_for_preview
        value = self.value
        # I18n.l(value) if value
        if value.is_a?(Time)
          if @options.format == '24'
            value.strftime("%H:%M")
          elsif @options.format == 'AM/PM'
            value.strftime("%I:%M%P")
          end
        end
      end

      def field_options
        return {} if access_readonly?

        options = {}
        current_time = Time.zone.now.change(sec: 0, usec: 0)

        if @model.options.begin_from_now?
          begin_minutes_offset = @model.options.begin_from_now_minutes_offset.minutes.to_i
          options[:min] = (current_time + begin_minutes_offset).strftime("%H:%M")
        elsif @model.options.begin_from_time?
          options[:min] = @model.options.begin.strftime("%H:%M")
        elsif @model.options.begin_from_minutes_before_end?
          minutes_before_end = @model.options.minutes_before_end.minutes
          if @model.options.end_to_now?
            end_minutes_offset = @model.options.end_to_now_minutes_offset.minutes.to_i
            options[:min] = (current_time + end_minutes_offset - minutes_before_end).strftime("%H:%M")
          elsif @model.options.end_to_time?
            options[:min] = (@model.options.end - minutes_before_end).strftime("%H:%M")
          end
        end

        if @model.options.end_to_now?
          end_minutes_offset = @model.options.end_to_now_minutes_offset.minutes.to_i
          options[:max] = (current_time + end_minutes_offset).strftime("%H:%M")
        elsif @model.options.end_to_time?
          options[:max] = @model.options.end.strftime("%H:%M")
        elsif @model.options.end_to_minutes_since_begin?
          minutes_since_begin = @model.options.minutes_since_begin.minutes.to_i
          if @model.options.begin_from_now?
            begin_minutes_offset = @model.options.begin_from_now_minutes_offset.minutes.to_i
            options[:max] = (current_time + begin_minutes_offset + minutes_since_begin).strftime("%H:%M")
          elsif @model.options.begin_from_time?
            options[:max] = (@model.options.begin + minutes_since_begin).strftime("%H:%M")
          end
        end

        options
      end

      def min
        field_options[:min]
      end

      def max
        field_options[:max]
      end

    end
  end
end
