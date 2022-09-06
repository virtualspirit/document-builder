source 'https://rubygems.org'
git_source(:github) { |repo| "https://github.com/#{repo}.git" }

# Specify your gem's dependencies in document.gemspec.
gemspec

group :development do
  gem 'sqlite3'
end

# To use a debugger
# gem 'byebug', group: [:development, :test]

gem "activeentity", ">= 6.1.0", git: 'https://github.com/ihsaneddin/activeentity'
gem 'mongoid'
gem 'mongoid_search', github: 'mongoid/mongoid_search'
gem "ranked-model", "~> 0.4.7"
gem 'validates_timeliness', '~> 6.0.0.alpha1'
gem 'support', path: "../support"