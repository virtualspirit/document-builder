module Document
  class FormStep

    include Mongoid::Document

    store_in collection: "document-form-steps"

    field :document_uid, type: BSON::ObjectId
    field :step, type: Integer

  end
end