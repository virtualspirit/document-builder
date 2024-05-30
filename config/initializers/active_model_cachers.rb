ActiveModelCachers.config do |config|
  config.store = Rails.cache # specify where the cache will be stored
end

#patch
module AssociationCache
  extend ActiveSupport::Concern

  def clear_association_cache
    if defined?(super)
      super
    else
      _relations = [:has_one, :belongs_to, :has_many, :has_and_belongs_to_many].reduce([]) { |arr, rel| arr + self.class.reflect_on_all_associations(rel).map(&:name) }
      _relations.each do |assoc|
        association(assoc.to_sym).reset rescue nil
      end
      if @association_cache
        instance_variable_set('@association_cache', {})
      end
    end
  end

end

ActiveRecord::Base.send(:include, AssociationCache)

ActiveModelCachers::CacheService.class_eval do

  # def get_without_cache(binding, attr)
  #   query = get_query(binding, attr)
  #   if attr.is_a?(::ActiveRecord::Reflection::AssociationReflection) && binding.is_a?(::ActiveRecord::Base)
  #     #avoid load from association cache again
  #     binding.association(attr.name).reset
  #   end
  #   return binding ? binding.instance_exec(@id, &query) : query.call(@id) if @id and query.parameters.size == 1
  #   return binding ? binding.instance_exec(&query) : query.call
  # end

  def clean_ar_cache(models)
    return if not models.first.is_a?(::ActiveRecord::Base)
    models.each do |model|
      model.send(:clear_aggregation_cache) if model.respond_to?(:clear_aggregation_cache, true)
      model.clear_association_cache
    end
  end
end

ActiveModelCachers::ActiveRecord::AttrModel.class_eval do
  def query_association(binding, id)
    #avoid load from association cache again
    if binding.is_a?(::ActiveRecord::Base)
      binding.association(@column).reset
      return binding.association(@column).load_target
    end
    id = @reflect.active_record.where(id: id).limit(1).pluck(foreign_key).first if foreign_key != 'id'
    case
    when collection? ; return id ? @reflect.klass.where(@reflect.foreign_key => id).to_a : []
    when has_one?    ; return id ? @reflect.klass.find_by(foreign_key(reverse: true) => id) : nil
    else             ; return id ? @reflect.klass.find_by(primary_key => id) : nil
    end
  end
end

ActiveModelCachers::CacheService.class_eval do
  def define_callback_for_cleaning_cache(class_name, column, foreign_key, with_id, on: nil)
    return if @callbacks_defined
    @callbacks_defined = true
    clean = ->(id){ clean_at(with_id ? id : nil) }
    clean_ids = []
    fire_on = Array(on) if on

    #use base class
    class_name = class_name.constantize.base_class.name

    ActiveRecord::Extension.global_callbacks.instance_exec do
      on_nullify(class_name) do |nullified_column, get_ids|
        get_ids.call.each{|s| clean.call(s) } if nullified_column == column
      end

      after_touch1(class_name) do
        clean.call(@@column_value_cache.add(self.class, class_name, id, foreign_key, self).call)
      end

      after_touch2(class_name) do
        @@column_value_cache.clean_cache
      end

      after_commit1(class_name) do
        next if fire_on and not transaction_include_any_action?(fire_on)
        changed = column ? previous_changes.key?(column) : previous_changes.present?
         if changed || destroyed?
           clean.call(@@column_value_cache.add(self.class, class_name, id, foreign_key, self).call)
         end
      end

      after_commit2(class_name) do
        @@column_value_cache.clean_cache
      end

      before_delete1(class_name) do |id, model|
        clean_ids << @@column_value_cache.add(self, class_name, id, foreign_key, model)
      end

      before_delete2(class_name) do |_, model|
        clean_ids.each{|s| clean.call(s.call) }
        clean_ids = []
      end

      after_delete(class_name) do
        @@column_value_cache.clean_cache
      end
    end
  end
end

ActiveModelCachers::CacheServiceFactory.class_eval do

  private

  def self.get_cache_key(attr)
    class_name, column = attr.extract_class_and_column
    #use base class
    if const = class_name.safe_constantize
      class_name = const.base_class.name
    end

    return "active_model_cachers_#{class_name}_at_#{column}" if column
    foreign_key = attr.foreign_key(reverse: true)


    return "active_model_cachers_#{class_name}_by_#{foreign_key}" if foreign_key and foreign_key.to_s != 'id'
    return "active_model_cachers_#{class_name}"
  end


end

