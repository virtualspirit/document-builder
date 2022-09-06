module Document
  module Grape
    class Ability
      include CanCan::Ability

      def initialize(user, context)
        Document.permission_set.new.computed_permissions.call(self, context, user)
      end
    end
  end
end