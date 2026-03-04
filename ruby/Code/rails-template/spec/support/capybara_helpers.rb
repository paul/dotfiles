# frozen_string_literal: true

module CapybaraHelpers
  # rubocop:disable RSpec/Output -- intentional debugging helper
  def pp_html(node = page)
    node.each { pp_html(it) } and return if node.is_a?(Capybara::Result)

    node = node.current_scope if node.is_a?(Capybara::Session)
    node = node.find(:xpath, "/html") if node.is_a?(Capybara::Node::Document)

    case node.native
    when Nokogiri::XML::Element, Nokogiri::HTML4::Document # rack_test
      pp node.native
    when Capybara::Cuprite::Node
      pp Nokogiri::HTML(node.native.node.evaluate("this.outerHTML"))
    else
      warn "I don't know how to pretty-print HTML for #{node.native.class}. " \
           "Add it to #{__FILE__}:#{__LINE__}"
    end
    nil
  end
  # rubocop:enable RSpec/Output

  RSpec.configure do |config|
    %w[system js feature component].each do |type|
      config.include self, type:
    end
  end
end
