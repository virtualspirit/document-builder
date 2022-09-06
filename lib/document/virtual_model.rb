module Document
  class VirtualModel

    # include Mongoid::Document
    # include Mongoid::Attributes::Dynamic
    # include Mongoid::Timestamps
    # include Document::Concerns::Models::ActiveStorageBridge::Attached::Macros

    # Hack
    ARRAY_WITHOUT_BLANK_PATTERN = "!ruby/array:ArrayWithoutBlank"

    def dump
      self.class.dump(self).gsub(ARRAY_WITHOUT_BLANK_PATTERN, "")
    end

    class << self

      delegate :dump, :load, to: :coder, allow_nil: false

      def coder
        @_coder ||= Document.virtual_model_coder_class.new(self)
      end

      def attr_readonly?(attr_name)
        readonly_attributes.include? attr_name.to_s
      end

      def coder=(klass)
        raise ArgumentError, "#{klass} should be sub-class of #{Coder}." unless klass && klass < Coder

        @_coder = klass.new(self)
      end

      def name
        @_name
      end

      def name=(value)
        value = value.classify
        raise ArgumentError, "`value` isn't a valid class name" if value.blank?

        @_name = value
      end

      def nested_models
        @nested_models ||= {}
      end

      def build(name: nil, collection: nil, step: false)
        # if collection
        #   self.store_in collection: collection
        # end
        # self.name = name
        # klass = Class.new(self)
        # klass.name = name
        # klass
        klass = Class.new(self)
        klass.name = name
        klass = setup_model(klass, step)
        if collection
          klass.store_in collection: collection
        end
        klass
      end

      protected

      def setup_model klass, step=false
        klass.include Mongoid::Document
        klass.include Mongoid::Timestamps
        klass.include Document::Concerns::Models::ActiveStorageBridge::Attached::Macros
        klass.include Document::Concerns::VirtualModels::GeneralSearch
        klass.include Document::Concerns::VirtualModels::AdvancedSearch
        if step
          klass.include Document::Concerns::VirtualModels::Steps
        end
        klass.class_attribute :form_id
        klass
      end


    end

  end
end
