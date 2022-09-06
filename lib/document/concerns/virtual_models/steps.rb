module Document
  module Concerns
    module VirtualModels
      module Steps
        extend ActiveSupport::Concern

        included do

          field :_step, type: :boolean
          field :_current_step, type: :integer
          field :_total_step, type: :integer
          field :_steps_keywords, type: :array

          after_initialize do
            self._step = true
            self._steps_keywords ||= []
            set_total_step
            set_current_step
          end

          before_save do
            set_keywords_overriden
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

        def set_keywords_overriden
          search_fields.each do |index, fields|
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
