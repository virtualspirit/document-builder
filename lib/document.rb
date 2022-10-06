require_relative 'concern.rb'

require 'validates_timeliness'
require 'mongoid'
require 'mongoid_search'
# debugger
require 'mongoid/geospatial'
require 'keisan'

require 'document/coder'
require 'document/coders/hash_coder'
require 'document/coders/yaml_coder'

require 'document/errors'
require 'document/concerns/models/active_storage_bridge/attached/macros'
require 'document/concerns/models/acts_as_default_value'
require 'document/concerns/models/enum_attribute_localizable'
require 'document/concerns/models/fields/helper'
require 'document/concerns/models/form'
require 'document/concerns/models/field'
require 'document/concerns/models/is_document'
require 'document/field_options'
require 'document/non_configurable_field'
require 'document/virtual_model'
require 'document/virtual_options'
require 'document/concerns/virtual_models/general_search'
require 'document/concerns/virtual_models/advanced_search'
require 'document/concerns/virtual_models/steps'

require 'document/concerns/models/field'
require 'document/concerns/models/form'
%w[acceptance confirmation exclusion format inclusion length numericality presence file].each do |file|
  require "document/concerns/models/fields/validations/#{file}"
end

%w[subset_validator].each do |file|
  require "document/concerns/models/fields/validators/#{file}"
end

require 'document/patches/active_support/prependable'
require 'grape_api'
require 'support'
require 'document/configuration/api'
require 'document/configuration'
require "document/version"
require "document/engine"

module Document
  # Your code goes here...
  extend Configuration

end

require 'document/grape'