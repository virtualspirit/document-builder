module Document
  module Grape
    module Authorization

      def self.included base
        base.extend ClassMethods
        ::Grape::Endpoint.include HelperMethods if defined? ::Grape::Endpoint
      end

      module ClassMethods
        def document_authorize_routes!
          before { document_authorize_route! }
        end
      end

      module HelperMethods

        def document_authorize_route!
          opts = env['api.endpoint'].options[:route_options]
          document_authorize!(*opts[:authorize]) if opts.key?(:authorize)
        end

        def document_authorize!

        end

      end
    end
  end
end