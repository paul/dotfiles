# frozen_string_literal: true

# Subscribe to everything, useful for debugging
# ActiveSupport::Notifications.subscribe(/.*/) do |name, start, finish, id, payload|
#   ap name:, start:, finish:, id:, payload:
# end

# Rails in production mode will eager-load everything under ./app, while in
# dev/test it will not. Since subscribers are never referred by constant name,
# the Rails autoloader will never require them. This code forcibly requires each
# subscriber in a auto-reloading-friendly way.
unless Rails.env.production?
  Rails.application.config.after_initialize do
    %w[
      app/subscribers/**/*.rb
      app/**/*_subscriber.rb
      app/**/subscriber.rb
    ].each do |path|
      Rails.root.glob(path).each do |file|
        require_dependency file
      end
    end
  end
end
