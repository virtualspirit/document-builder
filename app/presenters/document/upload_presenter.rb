module Document
  class UploadPresenter < SimpleDelegator

    def initialize(model)
      super(model)
      @model = model
    end

    def present
      res = {
        id: @model.id,
        file_data: JSON.parse(@model.file_data || "{}"),
        metadata: @model.metadata,
        uploadable_type: @model.uploadable_type,
        uploadable_id: @model.uploadable_id,
        created_at: @model.created_at,
        updated_at: @model.updated_at,
        order: @model.order,
        description: @model.description,
      }
      if Support.uploadable.shrine.storages.dig(:store).is_a?(Shrine::Storage::FileSystem)
        res[:file_url] = "#{ENV['BASE_URL'] || 'http://localhost:3000'}#{@model.file_url}"
      else
        res[:file_url] = @model.file_url
      end
    end

  end
end