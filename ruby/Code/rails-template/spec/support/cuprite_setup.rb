# frozen_string_literal: true

# First, load Cuprite Capybara integration
require "capybara/cuprite"

# Then, we need to register our driver to be able to use it later
# with #driven_by method.
#
# NOTE: The name :cuprite is already registered by Rails.
# See https://github.com/rubycdp/cuprite/issues/180
Capybara.register_driver(:better_cuprite) do |app|
  remote_chrome_url = ENV.fetch("CHROME_URL", "")

  # Chrome doesn't allow connecting to CDP by hostnames (other than localhost), but allows using IP
  # addresses.
  if remote_chrome_url&.match?(/host.docker.internal/)
    require "resolv"

    uri = URI.parse(remote_chrome_url)
    ip = Resolv.getaddress(uri.host)

    remote_chrome_url = remote_chrome_url.sub("host.docker.internal", ip)
  end

  ci = ENV["CI"].present?
  remote_options = remote_chrome_url.present? ? { url: remote_chrome_url } : {}
  browser_options = remote_chrome_url.present? || ci ? { "no-sandbox" => nil } : {}

  Capybara::Cuprite::Driver.new(
    app,
    window_size:     [1200, 800],
    # Increase Chrome startup wait time (required for stable CI builds)
    process_timeout: 10,
    # Enable debugging capabilities
    inspector:       true,
    # Allow running Chrome in a headful mode by setting HEADLESS env var to a falsey value
    headless:        !ENV.fetch("HEADLESS", "true").match?(/\A(false|no|0)\z/i),
    # See additional options for Dockerized environment in the respective section of this article
    browser_options:,
    **remote_options,
  )
end

Capybara.default_driver = :rack_test
Capybara.javascript_driver = :better_cuprite

module CupriteHelpers
  # Drop #pause anywhere in a test to stop the execution.
  # Useful when you want to checkout the contents of a web page in the middle of a test
  # running in a headful mode.
  def pause
    page.driver.pause
  end

  # Drop #debug anywhere in a test to open a Chrome inspector and pause the execution
  def debug(*)
    page.driver.debug(*)
  end
end

RSpec.configure do |config|
  config.include CupriteHelpers, type: :js

  # Make sure this hook runs before others
  config.prepend_before(:each, type: :system) do |example|
    driven_by example.metadata[:js] ? Capybara.javascript_driver : Capybara.default_driver
  end
end
