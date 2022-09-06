module Document
  class ApplicationPresenter < SimpleDelegator
    def initialize(model, section, options = {})
      super(model)

      @model = model
      @section = section
      @options = options
    end
  end
end
