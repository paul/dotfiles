# frozen_string_literal: true

RSpec::Matchers.define :have_html_attributes do |expected|
  match do |node|
    @actual = node.attributes.transform_values(&:value)
    expected.all? { |key, value| @actual[key] == value }
  end

  failure_message do
    "expected node to have HTML attributes #{expected.inspect}\n" \
      "but got #{@actual.inspect}"
  end

  diffable
end
