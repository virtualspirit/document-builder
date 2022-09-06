Document.setup do |config|
  # config.virtual_model_class = Document::VirtualModel
  # config.virtual_model_coder_class= Document::Coders::Hash
  # config.api do
    # setup_callbacks do

    #   callback_of :form_got_resource do |resource|
    #     resource.owner = current_user if resource.new_record?
    #   end
    #   callback_of :form_query_scope do |query|
    #     query
    #   end

    #   callback_of :section_got_resource do |resource|
    #     resource.form = form
    #   end
    #   callback_of :section_query_scope do |query|
    #     query.where(form: form).rank(:position)
    #   end

    #   callback_of :section_got_resource do |resource|
    #     resource.form = form
    #   end
    #   callback_of :section_query_scope do |query|
    #     query.where(form: form).rank(:position)
    #   end

    #   callback_of :field_got_resource do |resource|
    #     resource.form = form
    #   end
    #   callback_of :field_query_scope do |query|
    #     query.where(form: form).rank(:position)
    #   end

    #   callback_of :instance_got_resource do |resource|
    #     resource
    #   end
    #   callback_of :instance_query_scope do |query|
    #     query
    #   end

    #   callback_of :query_builder_got_resource do |resource|
    #     resource.form = form
    #     #resource.context = current_user
    #   end
    #   callback_of :query_builder_query_scope do |query|
    #     query.where(form: form)
    #   end
    # end

  #   set_current_user do
  #     User.first
  #   end
  #   draw_permissions do
  #     permission :manage_all, action: :manage, subject: :all, if: -> (user) { user.try(:admin) }
  #     group :form, model_name: "Document::Form" do

  #       # permission :read, if: -> (user) { user.try(:admin) }
  #       permission :read_owned, condition_proc: -> (user) { {owner_id: user.id, owner_type: user.class.name} }
  #       permission :create
  #       permission :update_owned, condition_proc: -> (user) { {owner_id: user.id, owner_type: user.class.name} }
  #       permission :update
  #       permission :delete_owned, condition_proc: -> (user) { {owner_id: user.id, owner_type: user.class.name} }
  #       permission :delete

  #       group :section, model_name: "Document::Section" do
  #         # permission :read, if: -> (user) { user.try(:admin) }
  #         permission :read_owned, if: -> (user) { form.owner == user }
  #         # permission :read_owned, condition_proc: -> (user) { {form_id: Document.form_model_class_constant.where(owner: user).pluck(:id)} }
  #         permission :create, if: -> (user) { user.try(:admin) || form.owner == user }
  #         permission :update_owned, if: -> (user) { form.owner == user }
  #         # permission :update_owned, condition_proc: -> (user) { {form_id: Document.form_model_class_constant.where(owner: user).pluck(:id)} }
  #         permission :delete, if: -> (user) { user.try(:admin) }
  #         permission :delete_owned, if: -> (user) { form.owner == user }
  #         # permission :delete_owned, condition_proc: -> (user) { {form_id: Document.form_model_class_constant.where(owner: user).pluck(:id)} }
  #       end

  #       group :field, model_name: "Document::Field" do
  #         # permission :read, if: -> (user) { user.try(:admin) }
  #         permission :read_owned, if: -> (user) { form.owner == user }
  #         # permission :read_owned, condition_proc: -> (user) { {form_id: Document.form_model_class_constant.where(owner: user).pluck(:id)} }
  #         permission :create, if: -> (user) { user.try(:admin) || form.owner == user }
  #         permission :update_owned, if: -> (user) { form.owner == user }
  #         # permission :update_owned, condition_proc: -> (user) { {form_id: Document.form_model_class_constant.where(owner: user).pluck(:id)} }
  #         permission :delete, if: -> (user) { user.try(:admin) }
  #         permission :delete_owned, if: -> (user) { form.owner == user }
  #         # permission :delete_owned, condition_proc: -> (user) { {form_id: Document.form_model_class_constant.where(owner: user).pluck(:id)} }
  #       end

  #       group :instance, model_name: "Document::Form" do
  #         # permission :read_instance, if: -> (user) { user.try(:admin) }
  #         permission :read_instance_owned, if: -> (user) { form.owner == user }
  #         #permission :create_instance, if: -> (user) { user.try(:admin) }
  #         permission :create_instance_owned, condition_proc: -> (user) { {owner_id: user.id, owner_type: user.class.name} }
  #         #permission :update_instance, if: -> (user) { user.try(:admin) }
  #         permission :update_instance_owned, condition_proc: -> (user) { {owner_id: user.id, owner_type: user.class.name} }
  #         #permission :delete_instance, if: -> (user) { user.try(:admin) }
  #         permission :delete_instance_owned, condition_proc: -> (user) { {owner_id: user.id, owner_type: user.class.name} }
  #       end

  #       group :query_builder, model_name: "Document::QueryBuilder" do
  #         # permission :read, if: -> (user) { user.try(:admin) }
  #         permission :read_owned, if: -> (user) { form.owner == user }
  #         #permission :create_instance, if: -> (user) { user.try(:admin) }
  #         permission :create, if: -> (user) { user.admin || form.owner == user }
  #         #permission :update, if: -> (user) { user.try(:admin) }
  #         permission :update_owned, condition_proc: -> (user) { {context_id: user.id, context_type: user.class.name} }
  #         #permission :delete, if: -> (user) { user.try(:admin) }
  #         permission :delete_owned, condition_proc: -> (user) { {context_id: user.id, context_type: user.class.name} }
  #       end

  #     end
  #   end
  # end
end