module Document
  module Configuration

    include Document::Configuration::Api

    def form_model_class
      @form_model_class ||= 'Document::Form'
    end

    def form_model_class_constant
      @form_model_class.is_a?(String) ? @form_model_class.constantize : @form_model_class
    end

    def form_model_class=(klass)
      raise ArgumentError, "#{klass} should be sub-class of #{Document::Form}." unless klass && klass < Document::Form

      @form_model_class = klass
    end

    def virtual_model_class
      @virtual_model_class ||= VirtualModel
    end

    def virtual_model_class=(klass)
      raise ArgumentError, "#{klass} should be sub-class of #{VirtualModel}." unless klass && klass < VirtualModel

      @reserved_names = nil
      @virtual_model_class = klass
    end

    def reserved_names
      @reserved_names ||= Set.new(
        %i[def class module private public protected allocate new parent superclass] +
          virtual_model_class.instance_methods(true)
      )
    end

    def virtual_model_coder_class
      @virtual_model_coder_class ||= Document::Coders::YAMLCoder
    end

    def virtual_model_coder_class=(klass)
      raise ArgumentError, "#{klass} should be sub-class of #{Coder}." unless klass && klass < Coder

      @virtual_model_coder_class = klass
    end

    def setup &block
      yield self
    end

  end
end