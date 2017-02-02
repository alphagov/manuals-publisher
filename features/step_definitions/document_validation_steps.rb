Then(/^I should see an error message about a "(.*?)" field containing javascript$/) do |field|
  check_for_javascript_usage_error(field)
end

Then(/^I see a warning about slug clash at publication$/) do
  check_for_slug_clash_warning
end
