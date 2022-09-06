require_relative "document/patches/active_support/prependable"

module ActiveSupport
  module Concern
    prepend Document::Patches::ActiveSupport::Prependable
  end
end