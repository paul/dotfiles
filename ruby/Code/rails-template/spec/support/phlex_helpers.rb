# frozen_string_literal: true

module PhlexHelpers
  # Render a Phlex component to an HTML string.
  def render(component, &)
    component.call(&)
  end

  # Parse rendered HTML into a Nokogiri document for assertions.
  def parse_html(html)
    Nokogiri::HTML5.fragment(html)
  end

  RSpec.configure { |config| config.include self }
end
