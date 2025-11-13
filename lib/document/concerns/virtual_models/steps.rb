module Document
  module Concerns
    module VirtualModels
      module Steps
        extend ActiveSupport::Concern

        included do

          class_attribute :step
          self.step= true
          class_attribute :non_linear
          self.non_linear= true

          field :_step, type: :boolean
          field :_current_step, type: :integer
          field :_total_step, type: :integer
          field :_steps_keywords, type: :array
          field :_steps_taken, type: :array

          after_initialize do
            self._step = true
            self._steps_keywords ||= []
            set_total_step
            set_current_step if self._current_step.nil?
          end

          before_save do
            set_keywords_overriden
            set_steps_taken
            if _current_step < (_total_step - 1)
              self._current_step = _current_step + 1
            end
          end

          after_save do
            fs = Document::FormStep.where(document_uid: _id).first
            if fs
              fs.update step: self._current_step
            else
              Document::FormStep.create(document_uid: _id, step: self._current_step)
            end
          end

        end

        def set_total_step
          self._total_step = Document::Form::find(self.class.form_id).step_options.total rescue 0
        end

        def steps_completed?
          (_steps_taken || []).uniq.length >= self._total_step.to_i
        end

        def set_current_step step=nil
          step ||= _current_step
          if _current_step
            if _total_step < _current_step
              self._current_step = _total_step
            end
          else
            self._current_step = 0
          end
        end

        def set_steps_taken
          self._steps_taken ||= []
          self._steps_taken.delete self._current_step.to_i
          self._steps_taken << self._current_step.to_i
          self._steps_taken.uniq!
        end

        def set_keywords_overriden
          (search_fields || []).each do |index, fields|
            if(_current_step <= _total_step - 1)
              self._steps_keywords[_current_step] = get_keywords(fields)
            else
              self._steps_keywords[_current_step] = get_keywords(fields)
            end
            send("#{index}=", self._steps_keywords.flatten)
          end
        end

        def set_keywords
          #do nothing
        end

      end
    end
  end
end
