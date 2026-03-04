# frozen_string_literal: true

namespace :db do
  task rm_schema: :environment do
    rm "db/schema.rb", force: true
    rm "db/structure.sql", force: true
  end

  Rake::Task["db:reset"].clear
  desc "Nuke the dev db and migrate from scratch"
  task reset: :environment do
    %i[db:drop db:rm_schema db:migrate db:seed].each do |name|
      Rake::Task[name].invoke
      ActiveRecord::Base.connection_handler.clear_all_connections!
    end
  end
end
