module Document
  class ApplicationRecord < ActiveRecord::Base

    self.abstract_class = true

    include Document::Concerns::Models::ActsAsDefaultValue
    include Document::Concerns::Models::EnumAttributeLocalizable
    include Document::Concerns::Models::Cached

    def self.without_callbacks(*callbacks)
      saved_callbacks = save_current_callbacks(callbacks)
      remove_callbacks(callbacks)
      yield
      restore_callbacks(saved_callbacks)
    end

    private

    def self.save_current_callbacks(callbacks)
      callbacks.map { |callback| [callback, self.__callbacks[callback]] }.to_h
    end

    def self.remove_callbacks(callbacks)
      callbacks.each { |callback| reset_callbacks(callback) }
    end

    def self.restore_callbacks(saved_callbacks)
      saved_callbacks.each { |callback, chain| set_callbacks(callback, chain) }
    end

  end
end
