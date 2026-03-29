# frozen_string_literal: true

def source_paths
  dir = File.dirname(File.expand_path(__FILE__))
  [File.join(dir, "rails-template"), dir] + Array(super)
end

# ---------------------------------------------------------------------------
# Idempotency helpers
# ---------------------------------------------------------------------------

def gemfile_content
  IO.read(File.join(destination_root, "Gemfile"))
end

def gem_missing?(name)
  !gemfile_content.match?(/^\s*gem ['"]#{Regexp.escape(name)}['"]/)
end

def gem_if_missing(name, *args, **opts)
  return unless gem_missing?(name)

  if opts.any?
    gem(name, *args, **opts)
  elsif args.any?
    gem(name, *args)
  else
    gem(name)
  end
end

def content_includes?(file, text)
  path = File.join(destination_root, file)
  File.exist?(path) && IO.read(path).include?(text)
end

def safe_commit(message)
  git add: "-A"
  run "git diff --cached --quiet || git commit -m '#{message}'"
end

# ---------------------------------------------------------------------------
# Gems
# ---------------------------------------------------------------------------

# Functional
gem_if_missing "dry-auto_inject"
gem_if_missing "dry-container"
gem_if_missing "dry-initializer"
gem_if_missing "dry-monads"
gem_if_missing "dry-schema"
gem_if_missing "dry-system"
gem_if_missing "dry-transaction"
gem_if_missing "dry-transaction-extra"
gem_if_missing "dry-types"
gem_if_missing "dry-validation"

# View
gem_if_missing "phlex"
gem_if_missing "phlex-rails"

# Util
gem_if_missing "progress_bar"
gem_if_missing "http", "~> 5.3"

gem_group :development, :test do
  gem_if_missing "awesome_print"

  # Livereload
  gem_if_missing "hotwire-spark"

  # Component previews
  gem_if_missing "lookbook"

  # Testing
  gem_if_missing "rspec"
  gem_if_missing "rspec-rails"

  gem_if_missing "capybara"
  gem_if_missing "cuprite"

  gem_if_missing "factory_bot_rails"
  gem_if_missing "faker"

  # Linting
  gem_if_missing "database_consistency", require: false
  gem_if_missing "reek",                 require: false
  gem_if_missing "rubocop",              require: false
  gem_if_missing "rubocop-capybara",     require: false
  gem_if_missing "rubocop-factory_bot",  require: false
  gem_if_missing "rubocop-performance",  require: false
  gem_if_missing "rubocop-rails",        require: false
  gem_if_missing "rubocop-rspec",        require: false
  gem_if_missing "rubocop-rspec_rails",  require: false
end

gem_group :development do
  gem_if_missing "annotaterb"
  gem_if_missing "pessimize"
  gem_if_missing "rails-erd"

  gem_if_missing "overmind"

  gem_if_missing "ruby-lsp", require: false
end

after_bundle do
  # Set version constraints on gems (only if they're not already pinned)
  run "pessimize -c minor --no-backup" unless gemfile_content.match?(/~>/)

  # Append optional gems as comments — uncomment and `bundle install` as needed
  unless content_includes?("Gemfile", "Optional — uncomment")
    append_to_file "Gemfile", <<~RUBY

      # Optional — uncomment and run `bundle install` as needed:
      # gem "literal"
      # gem "lucide-rails"
      # gem "pagy"
      # gem "commonmarker"
      # gem "marksmith"
      # gem "image_processing", "~> 1.14"
    RUBY
  end

  # Only init + initial-commit on brand new repos
  unless File.exist?(File.join(destination_root, ".git"))
    git :init
    safe_commit("Initial commit")
  end

  %i[
    rspec:install
    phlex:install
    erd:install
    annotate_rb:install
  ].each do |install|
    # Skip generators whose marker files are already present
    marker = {
      "rspec:install"       => ".rspec",
      "phlex:install"       => "config/initializers/phlex.rb",
      "erd:install"         => ".erdconfig",
      "annotate_rb:install" => ".annotaterb.yml",
    }[install.to_s]

    if marker && File.exist?(File.join(destination_root, marker))
      say "Skipping #{install} (#{marker} already exists)", :yellow
      next
    end

    generate install
    safe_commit("Generate #{install} files")
  end

  # --- Linter configs ---
  template ".rubocop.yml.tt", ".rubocop.yml", force: true
  copy_file ".reek.yml", force: true
  copy_file ".oxlintrc.json", force: true
  copy_file ".stylelintrc.json", force: true

  safe_commit("Add linter configs")

  # --- annotaterb config ---
  copy_file ".annotaterb.yml", force: true

  safe_commit("Add annotaterb config")

  # --- Generator config + application settings ---
  unless content_includes?("config/application.rb", "config.autoload_paths << ")
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
  end

  # autoload_lib must follow config.load_defaults in application.rb
  unless content_includes?("config/application.rb", "config.autoload_lib(ignore:")
    inject_into_file "config/application.rb",
                     "    config.autoload_lib(ignore: %w[assets rubocop tasks])\n\n",
                     after: /config\.load_defaults.*\n/
  end

  safe_commit("Update application config")

  # --- BetterMigrationDefaults (adapter-specific) ---
  unless File.exist?(File.join(destination_root, "lib/better_migration_defaults.rb"))
    if options[:database] == "postgresql"
      copy_file "lib/better_migration_defaults_postgresql.rb", "lib/better_migration_defaults.rb"
    else
      copy_file "lib/better_migration_defaults_sqlite.rb", "lib/better_migration_defaults.rb"
      copy_file "app/lib/string_enum.rb"
      copy_file "lib/tasks/db.rake"
    end
  end

  copy_file "lib/templates/active_record/migration/migration.rb.tt", force: true
  copy_file "lib/templates/active_record/migration/create_table_migration.rb.tt", force: true

  safe_commit("Add BetterMigrationDefaults and migration templates")

  # --- Custom RuboCop cops ---
  template "lib/rubocop/cop/app/transaction_best_practice.rb.tt",
           "lib/rubocop/cop/#{app_name}/transaction_best_practice.rb",
           force: true
  template "lib/rubocop/cop/app/initializer_dependencies.rb.tt",
           "lib/rubocop/cop/#{app_name}/initializer_dependencies.rb",
           force: true
  copy_file "lib/rubocop/cop/phlex/block_style.rb", force: true

  safe_commit("Add custom RuboCop cops")

  # --- Form base class ---
  copy_file "app/lib/form.rb", force: true

  safe_commit("Add Form base class")

  # --- Spec support infrastructure (overwrite rspec:install defaults) ---
  copy_file "spec/spec_helper.rb", force: true
  copy_file "spec/rails_helper.rb", force: true
  copy_file "spec/support/shared_contexts/with_transaction_context.rb", force: true
  copy_file "spec/support/matchers/fail_in_matcher.rb", force: true
  copy_file "spec/support/phlex_helpers.rb", force: true
  copy_file "spec/support/capybara_setup.rb", force: true
  copy_file "spec/support/cuprite_setup.rb", force: true
  copy_file "spec/support/capybara_helpers.rb", force: true
  copy_file "spec/support/app_selector.rb", force: true
  copy_file "spec/support/have_html_attributes_matcher.rb", force: true
  copy_file "spec/support/test_model.rb", force: true

  safe_commit("Add spec support infrastructure")

  # --- CI additions (inject into Rails-generated config/ci.rb) ---
  if File.exist?(File.join(destination_root, "config/ci.rb")) &&
     !content_includes?("config/ci.rb", "Database: Consistency")
    inject_into_file "config/ci.rb", before: /^\s*step "Security/ do
      <<~RUBY
        # step "Style: JavaScript", "oxlint app/javascript/"
        # step "Style: CSS/SCSS", 'bunx stylelint "app/assets/stylesheets/**/*.{css,scss}"'

        step "Database: Consistency", "bin/database_consistency"

      RUBY
    end

    safe_commit("Add database consistency and linter steps to CI")
  end

  # --- Documentation ---
  template "docs/STYLE.md.tt",        "STYLE.md",        force: true
  template "docs/ARCHITECTURE.md.tt", "ARCHITECTURE.md", force: true
  template "docs/AGENTS.md.tt",       "AGENTS.md",       force: true
  copy_file "docs/TESTING.md",        "TESTING.md",      force: true
  copy_file "docs/CONTRIBUTING.md",   "CONTRIBUTING.md", force: true
  copy_file "docs/REEK.md",           "REEK.md",         force: true
  copy_file ".github/PULL_REQUEST_TEMPLATE.md", force: true

  safe_commit("Add architecture and style documentation")

  # --- .env stubs ---
  create_file ".envrc", <<~SH, skip: true
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

  create_file ".env", "", skip: true
  create_file ".env.local", "", skip: true

  # Force add, since these are ignored by default
  run "git add .envrc .env --force"
  run "git diff --cached --quiet || git commit -m 'Add stub .env files'"

  # --- Phlex view layer ---
  copy_file "config/initializers/phlex.rb", force: true
  copy_file "app/components/base.rb", force: true
  copy_file "app/components/README.md", force: true
  template "app/views/base.rb.tt", "app/views/base.rb", force: true
  template "app/views/layouts/application_layout.rb.tt",
           "app/views/layouts/application_layout.rb", force: true
  copy_file "app/views/README.md", force: true

  safe_commit("Set up Phlex view layer with component base classes")

  # --- Dry::System container ---
  template "config/initializers/dry_system.rb.tt", "config/initializers/dry_system.rb", force: true
  template "lib/app/system/container.rb.tt", "lib/#{app_name}/system/container.rb", force: true
  template "config/system/boot/core.rb.tt", "config/system/boot/core.rb", force: true

  safe_commit("Add Dry::System container and boot configuration")

  # --- Initializers ---
  copy_file "config/initializers/dartsass.rb", force: true
  copy_file "app/assets/stylesheets/README.md", force: true
  safe_commit("Add dartsass initializer")

  copy_file "config/initializers/subscribers.rb", force: true
  safe_commit("Add subscriber initializer")

  # --- Lookbook ---
  template "config/initializers/lookbook.rb.tt", "config/initializers/lookbook.rb", force: true
  unless content_includes?("config/routes.rb", "Lookbook::Engine")
    inject_into_file "config/routes.rb",
                     "  mount Lookbook::Engine, at: \"/lookbook\"\n\n",
                     after: "Rails.application.routes.draw do\n"
  end

  safe_commit("Add lookbook")
end
