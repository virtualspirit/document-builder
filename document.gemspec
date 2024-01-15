require_relative "lib/document/version"

Gem::Specification.new do |spec|
  spec.name        = "document"
  spec.version     = Document::VERSION
  spec.authors     = [""]
  spec.email       = ["ihsaneddin@gmail.com"]
  spec.homepage    = "https://github.com/ihsaneddin"
  spec.summary     = "Summary of Document."
  spec.description = "Description of Document."
  spec.license     = "MIT"

  # Prevent pushing this gem to RubyGems.org. To allow pushes either set the 'allowed_push_host'
  # to allow pushing to a single host or delete this section to allow pushing to any host.
  if spec.respond_to?(:metadata)
    spec.metadata["allowed_push_host"] = "Set to 'http://mygemserver.com'"
  else
    raise "RubyGems 2.0 or newer is required to protect against " \
      "public gem pushes."
  end

  spec.files = Dir["{app,config,db,lib}/**/*", "MIT-LICENSE", "Rakefile", "README.md"]

  spec.add_dependency "rails", "~> 7.0.3"
  spec.add_dependency "activeentity", ">= 6.1.0"
  spec.add_dependency 'mongoid', '~> 8.0.1'
  spec.add_dependency 'mongoid_search'
  spec.add_dependency 'mongoid-geospatial'
  spec.add_dependency "ranked-model", "> 0.4.9"
  spec.add_dependency 'validates_timeliness', '~> 6.0.0.alpha1'
  spec.add_dependency 'shrine', '~> 3.4.0'

  # spec.add_dependency 'support', ">= 2.0.0"
  # spec.add_dependency 'grape_api', ">= 2.0.0"
  spec.add_dependency 'options_model'
  spec.add_dependency 'keisan'

end
