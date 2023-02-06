source 'https://rubygems.org'
git_source(:github) { |repo| "https://github.com/#{repo}.git" }

# Specify your gem's dependencies in document.gemspec.
gemspec

group :development do
  gem 'sqlite3'
end

# To use a debugger
# gem 'byebug', group: [:development, :test]

gem "activeentity"
gem 'mongoid', '>= 8.0.2'
gem 'mongoid_search', github: 'mongoid/mongoid_search'
gem 'mongoid-geospatial'
gem "ranked-model", "~> 0.4.8"
gem 'validates_timeliness', '~> 6.0.0.alpha1'
gem 'keisan'
gem 'support', git: "https://github.com/ihsaneddin/support", branch: "upgrade/rails-7"# tag: "v2.0.0"
gem 'grape_api', git: "https://github.com/ihsaneddin/grape_api", branch: "upgrade/rails-7"#, tag: "v2.0.0"
gem 'psych', '< 4'