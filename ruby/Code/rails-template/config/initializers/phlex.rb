# frozen_string_literal: true

module Views
  extend Phlex::Kit

  module Layouts
    extend Phlex::Kit
  end
end

module Components
  extend Phlex::Kit
end

Rails.autoloaders.main.push_dir(
  Rails.root.join("app/views"), namespace: Views,
)

Rails.autoloaders.main.push_dir(
  Rails.root.join("app/components"), namespace: Components,
)
