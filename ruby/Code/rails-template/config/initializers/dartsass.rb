# frozen_string_literal: true

Rails.application.config.dartsass.builds = {
  "." => ".",
}

if Rails.env.development?
  Rails.application.config.dartsass.build_options = ["--no-charset", "--embed-sources"]
end
