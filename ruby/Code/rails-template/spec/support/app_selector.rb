# frozen_string_literal: true

# allows you to find a link/button/submit via the rel attribute
#
# ex: find(:app, 'edit-article').click
# will find: <a href='' rel='app:edit-article'>...</a>
#
Capybara.add_selector(:app_link) do
  xpath { |rel|
    # rubocop:todo Layout/LineLength
    ".//a[contains(./@rel,'app:#{rel}')] | .//button[contains(./@rel,'app:#{rel}')] | .//input[./@type='submit'][contains(./@rel,'app:#{rel}')]"
    # rubocop:enable Layout/LineLength
  }
end
