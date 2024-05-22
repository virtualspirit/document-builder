ActiveModelCachers.config do |config|
  config.store = Rails.cache # specify where the cache will be stored
end

#patch
ActiveModelCachers::CacheService.class_eval do
  def clean_ar_cache(models)
    return if not models.first.is_a?(::ActiveRecord::Base)
    models.each do |model|
      model.send(:clear_aggregation_cache) if model.respond_to?(:clear_aggregation_cache, true)
      model.send(:clear_association_cache) if model.respond_to?(:clear_association_cache)
    end
  end
end

