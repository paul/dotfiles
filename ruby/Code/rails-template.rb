# frozen_string_literal: true

# Functional
gem "dry-auto_inject"
gem "dry-container"
gem "dry-monads"
gem "dry-schema"
gem "dry-transaction"
gem "dry-transaction-extra"
gem "dry-types"
gem "dry-validation"

# View
gem "phlex"
gem "phlex-rails"

# Util
gem "progress_bar"
gem "http", "~> 5.3"

gem_group :development, :test do
  gem "awesome_print"

  # Livereload
  gem "hotwire-spark"

  # Testing
  gem "rspec"
  gem "rspec-rails"

  gem "factory_bot_rails"
  gem "faker"

  # Linting
  gem "bundle-audit",         require: false
  gem "database_consistency", require: false
  gem "reek",                 require: false
  gem "rubocop",              require: false
  gem "rubocop-factory_bot",  require: false
  gem "rubocop-performance",  require: false
  gem "rubocop-rails",        require: false
  gem "rubocop-rspec",        require: false
  gem "rubocop-rspec_rails",  require: false
end

gem_group :development do
  gem "annotaterb"
  gem "pessimize"
  gem "rails-erd"

  gem "overmind"

  gem "ruby-lsp", require: false
end
