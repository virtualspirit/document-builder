module Document
  module Concerns
    module Models
      module Cached

        class Config

          ATTS = [:namespace, :key, :expires_in, :invalidate_when, :invalidate_if, :value, :before_invalidate, :after_invalidate]

          attr_reader *ATTS
          attr_accessor :instance

          def initialize **opts
            @namespace = opts[:namespace]
            @key = opts[:key]
            @expires_in = opts[:expires_in] || 12.hours
            @invalidate_when = opts[:invalidate_when] || [:after_commit]
            @invalidate_if = opts[:invalidate_if] || true
            @value = opts[:value]
            @before_invalidate = opts[:before_invalidate]
            @after_invalidate = opts[:after_invalidate]
          end

          def namespace= val
            @namespace = val
          end

          def cache_key
            "#{get_namespace}#{get_key}"
          end

          def set_instance instance
            @instance= instance
          end

          ATTS.each do |me|
            define_method me do |opt=nil, &block|
              if opt.nil? && !block
                instance_variable_get("@#{me.to_s}")
              else
                if me == :invalidate_when
                  instance_variable_set("@#{me.to_s}", opt)
                else
                  instance_variable_set("@#{me.to_s}", block ? block : opt)
                end
              end
            end
            define_method "get_#{me.to_s}" do
              val = send(me)
              if val.is_a?(Proc) || val.is_a?(Symbol)
                if instance
                  case val
                  when Proc
                    val.arity.zero? ? instance.instance_exec(&val) : val.call(instance)
                  when Symbol
                    instance.send(val)
                  end
                end
              else
                val
              end
            end
          end

        end

        def self.included base
          base.base_class.class_attribute :_cached_
          base.base_class._cached_ = {}
          base.base_class.extend ClassMethods
        end

        module ClassMethods

          def cache_this _name, **opts, &block
            raise "Block is missing" unless block_given?
            config = Document::Concerns::Models::Cached::Config.new(**opts)
            block.arity.zero? ? config.instance_exec(&block) : yield(config)
            config.namespace _cached_namespace_ if config.namespace.nil?
            config.key do |record|
              "#{record.id.to_s}-#{_name.to_s}"
            end if config.key.nil?
            class_eval <<-METHOD
              def #{_name.to_s}
                _fetch_cached_('#{_name.to_s}')
              end
              def invalidate_cache_of_#{_name.to_s}
                _invalidate_cache_('#{_name.to_s}', true)
              end
            METHOD
            if invalidate_callback = config.invalidate_when
              invalidate_callback = [invalidate_callback].compact.uniq unless invalidate_callback.is_a?(Array)
              invalidate_callback.each do |callback|
                next
                send callback.to_sym do
                  unless instance_variable_get("@_#{_name}_invalidated")
                    _invalidate_cache_(_name)
                    instance_variable_set("@_#{_name}_invalidated", true)
                  end
                end
              end
            end
            set_cached _name, config
            include InstanceMethods
          end

          def _cached_namespace_
            "cached:#{self.base_class.name.underscore}:"
          end

          def _cache_base_name_
            self.base_class.name
          end

          def cached key=nil
            if self._cached_[_cache_base_name_].nil?
              self._cached_[_cache_base_name_] = {}
            end
            if key
              self._cached_[_cache_base_name_][key.to_sym]
            else
              self._cached_[_cache_base_name_]
            end
          end

          def set_cached key, val
            if self._cached_[_cache_base_name_].nil?
              self._cached_[_cache_base_name_] = {}
            end
            self._cached_[_cache_base_name_][key.to_sym]= val
          end

        end

        module InstanceMethods

          def _cached_config _name
            self.class.cached _name
          end

          def with_cached_config _name, &block
            raise "Block is missing" unless block_given?
            conf = _cached_config(_name)
            if conf
              conf.set_instance self
              yield(conf.dup)
            end
          end

          def _fetch_cached_(_name)
            _value_ = nil
            with_cached_config(_name) do |config|
              _value_ = ::Rails.cache.read(config.cache_key)
              if _value_.nil?
                _value_ = ::Rails.cache.fetch(config.cache_key, expires_in: config.get_expires_in) do
                  config.get_value
                end
              end
            end
            _value_
          end

          def _invalidate_cache_(_name, force = false)
            with_cached_config(_name) do |config|
              if force || config.get_invalidate_if
                config.get_before_invalidate unless force
                ::Rails.cache.delete(config.cache_key)
                config.get_after_invalidate unless force
              end
            end
          end

        end

      end
    end
  end
end