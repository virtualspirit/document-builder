module Document
  module Grape
    module Resource

      def self.included base
        base.class_eval do
          self.resourceful_params_[:authorize_resources] = false
          self.resourceful_params_[:authorize_resource] = false
        end
        base.extend ClassMethods
        Document::Grape::Services::Base.helpers HelperMethods
      end

      module ClassMethods

        def authorize_resources? authorize = nil
          authorize_resources = resourceful_params(:authorize_resources) if authorize.nil?
          set_resource_param(:authorize_resources, authorize_resources)
          authorize_resources
        end

        def authorize_resource? authorize = nil
          authorize_resource = resourceful_params(:authorize_resource) if authorize.nil?
          set_resource_param(:authorize_resource, authorize_resource)
          authorize_resource
        end

      end

      module HelperMethods

        def _set_resource(context)
          super
          _authorize_resource!(@_resource) if route.options[:authorize] || _authorize_resource?
        end

        def _query
          query = super
          if query
            if route.options[:authorize] || _authorize_resources?
              unless route.options[:skip_authorization_scope]
                query = authorize_query_scope(query)
              end
            end
          end
          query
        end

        def _set_collection(context)
          super
          _authorize_resources!(@_resources) if route.options[:authorize] || _authorize_resources?
        end

        def _authorize_resource?
          return class_context do |context|
            authorize = context.authorize_resource?
            case authorize
            when Proc
              return authorize.call
            else
              return authorize
            end
          end
        end

        def _authorize_resources?
          return class_context do |context|
            authorize = context.authorize_resources?
            case authorize
            when Proc
              return authorize.call
            else
              return authorize
            end
          end
        end

        attr_accessor :authorized_action

        def _authorize_resources! __resources = nil
          opts = route.options
          if opts.key?(:authorize)
            authorization_opts= opts[:authorize].dup
            if authorization_opts.length == 2
              _resources_ = authorization_opts.last
              case _resources_
              when Symbol
                authorization_opts[1] = self.send(_resources_) if respond_to?(_resources_)
              when String
                if _resources_[0] == "@"
                  authorization_opts[1] = instance_variable_get(_resources_)
                else
                  authorization_opts[1] = self.send(_resources_) if respond_to?(_resources_)
                end
              end
              return if authorization_opts.last.nil?
            elsif authorization_opts.length == 1
              authorization_opts[1] = __resources
            end
            if authorization_opts[0].is_a?(Array)
              authorized = false
              authorization_opts[0].each do |act|
                authorized = can? act, authorization_opts[1]
                if authorized
                  self.authorized_action = act
                  break
                end
              end
              unless authorized
                raise ::CanCan::AccessDenied.new("Unauthorized", authorization_opts[0], authorization_opts[1], [])
              end
            else
              current_ability.authorize!(*authorization_opts)
              self.authorized_action= authorization_opts[0]
            end
          end
        end

        def _authorize_resource! __resource = nil
          _authorize_resources! __resource
        end

        def authorize_query_scope query
          if current_ability && self.authorized_action
            query = query.accessible_by(current_ability, self.authorized_action)
          end
          query
        end

      end

    end
  end
end