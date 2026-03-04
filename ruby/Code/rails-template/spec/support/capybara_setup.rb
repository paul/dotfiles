# frozen_string_literal: true

# Use the same server as dev
Capybara.server = :puma
# Make server listening on all hosts
Capybara.server_host = "0.0.0.0"
# Use a hostname accessible from the outside world
# Capybara.app_host = "http://localhost:5001"

# Usually, especially when using Selenium, developers tend to increase the max wait time.
# With Cuprite, there is no need for that.
# We use a Capybara default value here explicitly.
Capybara.default_max_wait_time = 2

# Normalize whitespaces when using `has_text?` and similar matchers, i.e., ignore newlines, trailing
# spaces, etc. That makes tests less dependent on slight UI changes.
Capybara.default_normalize_ws = true

# Where to store system tests artifacts (e.g. screenshots, downloaded files, etc.).
# It could be useful to be able to configure this path from the outside (e.g., on CI).
Capybara.save_path = ENV.fetch("CAPYBARA_ARTIFACTS", "./tmp/capybara")

# The Capybara.using_session allows you to manipulate a different browser session, and thus,
# multiple independent sessions within a single test scenario.
Capybara.singleton_class.prepend(Module.new do
  attr_accessor :last_used_session

  def using_session(name, &)
    self.last_used_session = name
    super
  ensure
    self.last_used_session = nil
  end
end)

module BetterRailsSystemTests
  # Use relative path in screenshot message to make it clickable in VS Code when running in Docker
  def image_path
    relpath = Pathname.new(absolute_image_path).relative_path_from(Rails.root).to_s

    # If using a terminal that supports hyperlinks, make the image clickable
    if output_type == "hyperlink"
      relpath = "\e]8;;file:///#{absolute_image_path}\e\\#{relpath}\e]8;;\e\\\n"
    end

    relpath
  end

  # Make failure screenshots compatible with multi-session setup. That's where we use
  # Capybara.last_used_session introduced before.
  def take_screenshot
    return super unless Capybara.last_used_session

    Capybara.using_session(Capybara.last_used_session) { super }
  end

  # Convert dom_id to selector
  def dom_id(*args)
    "##{super}"
  end
end

RSpec.configure do |config|
  %i[system js feature].each do |type|
    config.include ActionView::RecordIdentifier, type: type
    config.include BetterRailsSystemTests, type: type
  end

  # Make urls in mailers contain the correct server host.
  config.around(:each, type: :system) do |ex|
    was_host, Rails.application.default_url_options[:host] =
      Rails.application.default_url_options[:host], Capybara.server_host
    ex.run
    if was_host
      Rails.application.default_url_options[:host] = was_host
    else
      Rails.application.default_url_options.delete(:host)
    end
  end
end
