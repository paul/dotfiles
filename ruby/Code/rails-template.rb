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

after_bundle do
  # Set version constraints on gems
  run "pessimize -c minor --no-backup"

  git :init
  git add: "."
  git commit: "-a -m 'Initial commit'"

  %i[
    rspec:install
    phlex:install
    erd:install
    annotate_rb:install
  ].each do |install|
    generate install
    git add: "."
    git commit: "-a -m 'Generate #{install} files'"
  end

  file ".annotaterb.yml", <<~YAML
    ---
    :position: bottom
    :position_in_additional_file_patterns: bottom
    :position_in_class: bottom
    :position_in_factory: bottom
    :position_in_fixture: bottom
    :position_in_routes: bottom
    :position_in_serializer: bottom
    :position_in_test: bottom
    :classified_sort: true
    :exclude_controllers: true
    :exclude_factories: false
    :exclude_fixtures: false
    :exclude_helpers: true
    :exclude_scaffolds: true
    :exclude_serializers: false
    :exclude_sti_subclasses: false
    :exclude_tests: false
    :force: false
    :format_markdown: false
    :format_rdoc: false
    :format_yard: false
    :frozen: false
    :ignore_model_sub_dir: false
    :ignore_unknown_models: false
    :include_version: false
    :show_check_constraints: false
    :show_complete_foreign_keys: false
    :show_foreign_keys: true
    :show_indexes: true
    :simple_indexes: false
    :sort: false
    :timestamp: false
    :trace: false
    :with_comment: true
    :with_column_comments: true
    :with_table_comments: true
    :active_admin: false
    :command:
    :debug: false
    :hide_default_column_types: ""
    :hide_limit_column_types: ""
    :timestamp_columns:
      - created_at
      - updated_at
      - discarded_at
    :ignore_columns:
    :ignore_routes:
    :models: true
    :routes: false
    :skip_on_db_migrate: false
    :target_action: :do_annotations
    :wrapper:
    :wrapper_close:
    :wrapper_open:
    :classes_default_to_s: []
    :additional_file_patterns: []
    :model_dir:
      - app/models
    :require: []
    :root_dir:
      - ""
  YAML

  git add: ".annotaterb.yml"
  git commit: "-a -m 'Add annotaterb config'"

  environment <<~RUBY
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

        # Annotate any models/fixtures/factores we generate after the migration has run
        system(*%w[bundle exec annotaterb models], exception: true)
      end
    end
  RUBY

  git add: "config/application.rb"
  git commit: "-a -m 'Update generators config'"

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
  git commit: "-a -m 'Add stub .env files'"
end
