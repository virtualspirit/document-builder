module Document
  module Grape
    module Cancan

      def self.included base
        base.extend ClassMethods
        base.helpers HelperMethods
        base.class_eval do
          rescue_from ::CanCan::AccessDenied do
            error!("Access denied!. 403 Forbidden", 403)
          end
        end

      end

      module ClassMethods
        def authorize_routes!
          before { authorize_route! }
        end
      end

      module HelperMethods

        def current_user
          @current_user ||= instance_exec(&Document.current_user) if Document.current_user.is_a?(Proc)
        end

        def current_ability
          @current_ability ||= {}
          @current_ability[context.base.name] ||= Document.ability_class_constant.new(current_user, self)
          @current_ability[context.base.name]
        end
        delegate :can?, :cannot?, :authorize!, to: :current_ability

        def authorize_route!
          opts = env['api.endpoint'].options[:route_options]
          current_ability.authorize!(*opts[:authorize]) if opts.key?(:authorize)
        end
      end
    end
  end
end