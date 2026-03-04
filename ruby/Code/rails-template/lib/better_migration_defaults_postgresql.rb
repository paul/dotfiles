# frozen_string_literal: true

# Author:  Paul Sadauskas<paul@sadauskas.com>
# License: MIT

#
# Better defaults for Rails migrations
#
# Example:
#
# class CreateUsers < ActiveRecord::Migration[8.0]
#   using BetterMigrationDefaults
#
module BetterMigrationDefaults
  module BetterTimestamps
    # * Makes created_at and updated_at NOT NULL with a default
    # * Adds `discarded_at`
    # * Handles an `:except` list of timestamps to skip
    def timestamps(except: [], only: %i[created_at updated_at discarded_at], **)
      types = Array.wrap(only) - Array.wrap(except)
      opts = { null: false, default: -> { "now()" } }

      column :created_at,   :datetime, **opts if types.include?(:created_at)
      column :updated_at,   :datetime, **opts if types.include?(:updated_at)
      column :discarded_at, :datetime if types.include?(:discarded_at)
    end
  end

  # Rails thinks it should be generating index names, but fails miserably on
  # long ones, and postgres does fine on its own. There's no way to force Rails to let
  # postgres choose, but this implementation emulates what postgres would do.
  #
  # Fixes this error:
  # ArgumentError: Index name
  # 'index_long_table_name_on_long_column_one_and_long_column_two_and_long_column_three' on
  # table 'long_table_name' is too long; the limit is 63 characters
  module BetterIndexNaming
    module Migration
      def add_index(table_name, column_name, comment: nil, if_not_exists: true, **options)
        options[:name] ||= pg_index_name(table_name, column_name)
        options[:if_not_exists] = if_not_exists
        options[:algorithm] ||= :concurrently if ActiveRecord::Migration.disable_ddl_transaction
        super
      end

      def index_exists?(table_name, column_name, **options)
        options[:name] ||= pg_index_name(table_name, column_name)
        super
      end

      # Generate an index name using the same algorithm as postgres' default
      def pg_index_name(table_name, columns)
        columns = Array(columns).map { |col| col.tr("(", "_").delete(")").delete_prefix("_") }
        [table_name.to_s.first(29), *columns].join("_").first(59) + "_idx"
      end
    end
  end

  # Pick some better defaults for `references`:
  #  - on_delete: :cascade
  #  - null: false
  #  - name: {table}_{column}_fkey, rather than "fk_rails_9dc3aec2b1"
  #
  module BetterReferenceNaming
    # I'd rather use a refinement to alter the implementation of
    # `AR::ConnectionAdapters::SchemaStatements#foreign_key_name`, but since the Migration code
    # calls those methods using method_missing+send, the refinement doesn't persist.
    # https://www.honeybadger.io/blog/understanding-ruby-refinements-and-lexical-scope/#:~:text=You%20can%27t%20dynamically%20invoke%20a%20refinement%20method
    # Instead, I have to monkeypatch the Migration `add_foreign_key` method, and determine the
    # column names on my own
    def foreign_key_name(from_table, to_table, **options)
      columns = if options[:column]
                  Array(options[:column])
                elsif options[:primary_key]
                  Array(options[:primary_key]).map { |key| "#{to_table}_#{key}" }
                else
                  ["#{to_table.to_s.singularize}_id"]
                end

      # Postgres names have a limit of 63 characters. Use the first 29 characters of the table
      # name, then however much of the column names fit after that.
      [from_table.to_s.first(33), *columns].join("_").first(58) + "_fkey"
    end
    module_function :foreign_key_name

    module TableDefinition
      def references(*args, **options)
        args.each do |ref_name|
          options = options.dup
          unless options[:polymorphic]
            options[:foreign_key] = {} if !options.key?(:foreign_key) || options[:foreign_key] == true
            options[:foreign_key].reverse_merge!(
              on_delete: :cascade,
              name:      BetterReferenceNaming.foreign_key_name(name, ref_name, **options[:foreign_key]),
            )
          end
          options[:null] = false unless options.key?(:null)

          ActiveRecord::ConnectionAdapters::ReferenceDefinition.new(ref_name, **options).add_to(self)
        end
      end
    end

    module Migration
      def add_reference(table_name, ref_name, **options)
        unless options[:polymorphic]
          options[:foreign_key] = {} if !options.key?(:foreign_key) || options[:foreign_key] == true
          options[:foreign_key].reverse_merge!(
            on_delete: :cascade,
            name:      BetterReferenceNaming.foreign_key_name(table_name, ref_name, **options[:foreign_key]),
          )
        end
        options[:null] = false unless options.key?(:null)
        super
      end

      def add_foreign_key(from_table, to_table, **options)
        options[:on_delete] ||= :cascade
        options[:name] ||= BetterReferenceNaming.foreign_key_name(from_table, to_table, **options)
        super
      end
    end
  end

  # Often times in migrations you need longer statement and lock timeouts. Use this to set a
  # timeout for the duration of a block.
  module BetterTimeouts
    # Set the statement & lock timeout to a number of seconds
    #
    # Ex: set_timeout(10.minutes)
    def set_timeout(statement_timeout, lock_timeout = statement_timeout)
      statement_timeout = "#{statement_timeout.to_i}s" unless statement_timeout.is_a? String
      lock_timeout = "#{lock_timeout.to_i}s" unless lock_timeout.is_a? String
      safety_assured do
        say "Setting timeouts: statement_timeout=#{statement_timeout} lock_timeout=#{lock_timeout}"
        suppress_messages do
          execute "SET statement_timeout = '#{statement_timeout}'"
          execute "SET lock_timeout = '#{lock_timeout}'"
        end
      end
    end

    # Set the statement & lock timeout to a number of seconds for the duration of the block
    #
    # Ex: with_timeout(10.minutes) { run queries }
    def with_timeout(statement_timeout, lock_timeout = statement_timeout)
      original_statement_timeout = original_lock_timeout = nil
      suppress_messages do
        original_statement_timeout = select_value("SHOW statement_timeout")
        original_lock_timeout = select_value("SHOW lock_timeout")
      end

      set_timeout(statement_timeout, lock_timeout)
      yield
    ensure
      set_timeout(original_statement_timeout, original_lock_timeout)
    end
  end

  # If you blindly add a NOT NULL constraint to an existing column on a large table, it can be
  # slow while postgres checks that all the rows have a value, and it locks the table while doing
  # so. Instead, add a NOT VALID constraint (doesn't lock), validate the constraint (doesn't
  # lock), then add the NOT NULL (locks, but is fast because we already validated it). Finally,
  # drop the old constraint.
  #
  # Also, this can take a long time, so be sure to increase the timeout for the migration.
  module SafeAddNullConstraint
    def safe_add_column_not_null(table, column)
      constraint = "#{table}_#{column}_not_null"

      begin
        execute %{ALTER TABLE #{table} ADD CONSTRAINT #{constraint} CHECK (#{column} IS NOT NULL) NOT VALID}
      rescue ActiveRecord::StatementInvalid => ex
        # Makes this safe to re-run by ignoring duplicate constraint being added
        raise unless ex.cause.is_a?(PG::DuplicateObject)
      end

      execute %(ALTER TABLE #{table} VALIDATE CONSTRAINT #{constraint})

      change_column_null table, column, false

      execute %(ALTER TABLE #{table} DROP CONSTRAINT #{constraint})
    end
  end

  module SafeAddUniqueIndex
    def safe_add_unique_index(table_name, column_name, **options)
      name = options[:name] || pg_index_name(table_name, column_name)

      index_valid = connection.select_value(<<~SQL.squish)
        SELECT pg_index.indisvalid
        FROM pg_class, pg_index
        WHERE pg_class.relname = '#{name}'
        AND pg_index.indexrelid = pg_class.oid
      SQL

      case index_valid
      when nil # index doesn't exist yet, create it
        add_index(table_name, column_name, **options)

      when false # index exists, but is invalid. Try re-indexing it
        say "Fixing invalid index #{name}"
        remove_index(table_name, column_name, **options)
        add_index(table_name, column_name, **options)
      when true # index exists and is valid, do nothing
        :noop
      end
    end

    def safe_add_index(table_name, column_name, **)
      add_index(table_name, column_name, **) unless index_exists?(table_name, column_name, **)
    end

    def safe_remove_index(table_name, column_name, **)
      remove_index(table_name, column_name, **) if index_exists?(table_name, column_name, **)
    end

    # Generate an index name using the same algorithm as postgres' default
    def pg_index_name(table_name, columns)
      columns = Array(columns).map { |col| col.to_s.tr("(", "_").delete(")").delete_prefix("_") }
      [table_name.to_s.first(29), *columns].join("_").first(59) + "_idx"
    end
  end

  refine ActiveRecord::Migration do
    import_methods BetterIndexNaming::Migration
    import_methods BetterReferenceNaming::Migration
    import_methods BetterTimeouts
    import_methods SafeAddNullConstraint
    import_methods SafeAddUniqueIndex
  end

  refine ActiveRecord::ConnectionAdapters::PostgreSQL::TableDefinition do
    import_methods BetterReferenceNaming::TableDefinition
    import_methods BetterTimestamps
  end
end
