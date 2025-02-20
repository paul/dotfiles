# frozen_string_literal: true

gem "progress_bar"

gem_group :development, :test do
  gem "awesome_print"

  gem "rspec"
  gem "rspec-rails"

  gem "factory_bot_rails"

  gem "bundle-audit",         require: false
  gem "database_consistency", require: false
  gem "reek",                 require: false
  gem "rubocop",              require: false
  gem "rubocop-performance",  require: false
  gem "rubocop-rails",        require: false
  gem "rubocop-rspec",        require: false
end

gem_group :development do
  gem "annotate"
  gem "pessimize"
  gem "rails-erd"

  gem "overmind"
end
