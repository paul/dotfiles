# frozen_string_literal: true

def source_paths
  dir = File.dirname(File.expand_path(__FILE__))
  [File.join(dir, "rails-template"), dir] + Array(super)
end

# Functional
gem "dry-auto_inject"
gem "dry-container"
gem "dry-initializer"
gem "dry-monads"
gem "dry-schema"
gem "dry-system"
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

  # Component previews
  gem "lookbook"

  # Testing
  gem "rspec"
  gem "rspec-rails"

  gem "capybara"
  gem "cuprite"

  gem "factory_bot_rails"
  gem "faker"

  # Linting
  gem "database_consistency", require: false
  gem "reek",                 require: false
  gem "rubocop",              require: false
  gem "rubocop-capybara",     require: false
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

after_bundle do
  # Set version constraints on gems
  run "pessimize -c minor --no-backup"

  # Append optional gems as comments — uncomment and `bundle install` as needed
  append_to_file "Gemfile", <<~RUBY

    # Optional — uncomment and run `bundle install` as needed:
    # gem "literal"
    # gem "lucide-rails"
    # gem "pagy"
    # gem "commonmarker"
    # gem "marksmith"
    # gem "image_processing", "~> 1.14"
  RUBY

  git :init
  git add: "-A"
  git commit: "-m 'Initial commit'"

  %i[
    rspec:install
    phlex:install
    erd:install
    annotate_rb:install
  ].each do |install|
    generate install
    git add: "-A"
    git commit: "-m 'Generate #{install} files'"
  end

  # --- Linter configs ---
  template ".rubocop.yml.tt", ".rubocop.yml", force: true
  copy_file ".reek.yml"
  copy_file ".oxlintrc.json"
  copy_file ".stylelintrc.json"

  git add: "-A"
  git commit: "-m 'Add linter configs'"

  # --- annotaterb config ---
  copy_file ".annotaterb.yml", force: true

  git add: ".annotaterb.yml"
  git commit: "-m 'Add annotaterb config'"

  # --- Generator config + application settings ---
  environment <<~RUBY
    # I'd rather this be in the Lookbook initializer, but that gets loaded too late
    # https://github.com/lookbook-hq/lookbook/issues/698
    config.autoload_paths << "\#{root}/spec/components/previews"

    # Always use UTC
    ENV["TZ"] = "UTC"
    config.time_zone = "UTC"

    config.generators do |g|
      g.test_framework :rspec

      g.helper false
      g.system_tests false

      # Don't generate specs for these
      g.model_specs false
      g.controller_specs false
      g.helper_specs false
      g.routing_specs false
      g.view_specs false

      g.after_generate do |files|
        # If we generated with -p (pretend), the files won't exist, so no need to process them
        parsable_files = files.filter { |file| File.exist?(file) && file.end_with?(".rb") }
        next if parsable_files.empty?

        # After generating files, automatically fix them with rubocop
        system(
          *%w[bundle
              exec
              rubocop
              --autocorrect-all
              --fail-level=E
              --format=quiet
              --no-display-cop-names],
          *parsable_files,
          exception: true,
        )

        # Annotate any models/fixtures/factories we generate after the migration has run
        system(*%w[bundle exec annotaterb models], exception: true)
      end
    end
  RUBY

  # autoload_lib must follow config.load_defaults in application.rb
  inject_into_file "config/application.rb",
                   "    config.autoload_lib(ignore: %w[assets rubocop tasks])\n\n",
                   after: /config\.load_defaults.*\n/

  git add: "-A"
  git commit: "-m 'Update application config'"

  # --- BetterMigrationDefaults (adapter-specific) ---
  if options[:database] == "postgresql"
    copy_file "lib/better_migration_defaults_postgresql.rb", "lib/better_migration_defaults.rb"
  else
    copy_file "lib/better_migration_defaults_sqlite.rb", "lib/better_migration_defaults.rb"
    copy_file "app/lib/string_enum.rb"
    copy_file "lib/tasks/db.rake"
  end

  copy_file "lib/templates/active_record/migration/migration.rb.tt"
  copy_file "lib/templates/active_record/migration/create_table_migration.rb.tt"

  git add: "-A"
  git commit: "-m 'Add BetterMigrationDefaults and migration templates'"

  # --- Custom RuboCop cops ---
  template "lib/rubocop/cop/app/transaction_best_practice.rb.tt",
           "lib/rubocop/cop/#{app_name}/transaction_best_practice.rb"
  template "lib/rubocop/cop/app/initializer_dependencies.rb.tt",
           "lib/rubocop/cop/#{app_name}/initializer_dependencies.rb"
  copy_file "lib/rubocop/cop/phlex/block_style.rb"

  git add: "-A"
  git commit: "-m 'Add custom RuboCop cops'"

  # --- Form base class ---
  copy_file "app/lib/form.rb"

  git add: "-A"
  git commit: "-m 'Add Form base class'"

  # --- Spec support infrastructure (overwrite rspec:install defaults) ---
  copy_file "spec/spec_helper.rb", force: true
  copy_file "spec/rails_helper.rb", force: true
  copy_file "spec/support/shared_contexts/with_transaction_context.rb"
  copy_file "spec/support/matchers/fail_in_matcher.rb"
  copy_file "spec/support/phlex_helpers.rb"
  copy_file "spec/support/capybara_setup.rb"
  copy_file "spec/support/cuprite_setup.rb"
  copy_file "spec/support/capybara_helpers.rb"
  copy_file "spec/support/app_selector.rb"
  copy_file "spec/support/have_html_attributes_matcher.rb"
  copy_file "spec/support/test_model.rb"

  git add: "-A"
  git commit: "-m 'Add spec support infrastructure'"

  # --- CI additions (inject into Rails-generated config/ci.rb) ---
  inject_into_file "config/ci.rb", before: /^\s*step "Security/ do
    <<~RUBY
      # step "Style: JavaScript", "oxlint app/javascript/"
      # step "Style: CSS/SCSS", 'bunx stylelint "app/assets/stylesheets/**/*.{css,scss}"'

      step "Database: Consistency", "bin/database_consistency"

    RUBY
  end

  git add: "config/ci.rb"
  git commit: "-m 'Add database consistency and linter steps to CI'"

  # --- Documentation ---
  template "docs/STYLE.md.tt",        "STYLE.md"
  template "docs/ARCHITECTURE.md.tt", "ARCHITECTURE.md"
  template "docs/AGENTS.md.tt",       "AGENTS.md"
  copy_file "docs/TESTING.md",        "TESTING.md"
  copy_file "docs/CONTRIBUTING.md",   "CONTRIBUTING.md"
  copy_file "docs/REEK.md",           "REEK.md"
  copy_file ".github/PULL_REQUEST_TEMPLATE.md"

  git add: "-A"
  git commit: "-m 'Add architecture and style documentation'"

  # --- .env stubs ---
  create_file ".envrc", <<~SH
    # Load .env variables automatically with direnv
    # http://direnv.net/

    if [ -e ./.env ]
    then
      dotenv
    fi

    if [ -e ./.env.local ]
    then
      dotenv .env.local
    fi
  SH

  create_file ".env", ""
  create_file ".env.local", ""

  # Force add, since these are ignored by default
  run "git add .envrc .env --force"
  git commit: "-m 'Add stub .env files'"

  # --- Phlex view layer ---
  copy_file "config/initializers/phlex.rb", force: true
  copy_file "app/components/base.rb", force: true
  copy_file "app/components/README.md"
  template "app/views/base.rb.tt", "app/views/base.rb", force: true
  template "app/views/layouts/application_layout.rb.tt",
           "app/views/layouts/application_layout.rb", force: true
  copy_file "app/views/README.md"

  git add: "-A"
  git commit: "-m 'Set up Phlex view layer with component base classes'"

  # --- Dry::System container ---
  template "config/initializers/dry_system.rb.tt", "config/initializers/dry_system.rb"
  template "lib/app/system/container.rb.tt", "lib/#{app_name}/system/container.rb"
  template "config/system/boot/core.rb.tt", "config/system/boot/core.rb"

  git add: "-A"
  git commit: "-m 'Add Dry::System container and boot configuration'"

  # --- Initializers ---
  copy_file "config/initializers/dartsass.rb", force: true
  copy_file "app/assets/stylesheets/README.md"
  git add: "-A"
  git commit: "-m 'Add dartsass initializer'"

  copy_file "config/initializers/subscribers.rb"
  git add: "-A"
  git commit: "-m 'Add subscriber initializer'"

  # --- Lookbook ---
  template "config/initializers/lookbook.rb.tt", "config/initializers/lookbook.rb"
  inject_into_file "config/routes.rb",
                   "  mount Lookbook::Engine, at: \"/lookbook\"\n\n",
                   after: "Rails.application.routes.draw do\n"

  git add: "-A"
  git commit: "-m 'Add lookbook'"
end
