source "https://rubygems.org"

gem "rails", "6.0.3.6"

gem "gds-api-adapters"
gem "gds-sso"
gem "generic_form_builder"
gem "govspeak"
gem "govuk_admin_template"
gem "govuk_app_config"
gem "govuk_frontend_toolkit", "9.0.0" # we rely on this for correctly previewing govspeak (including interactive elements) - to help with that keep it in sync with the version used in manuals-frontend
gem "govuk_sidekiq"
gem "mongoid"
gem "plek"
gem "raindrops"
gem "sass-rails"
gem "state_machine"
gem "uglifier"

group :development do
  gem "better_errors"
  gem "binding_of_caller"
end

group :development, :test do
  gem "awesome_print"
  gem "govuk_test"
  gem "jasmine"
  gem "jasmine_selenium_runner"
  gem "pry-byebug"
end

group :test do
  gem "cucumber", require: false
  gem "cucumber-rails", require: false
  gem "database_cleaner-mongoid"
  gem "factory_bot_rails"
  gem "govuk-content-schema-test-helpers"
  gem "launchy"
  gem "rails-controller-testing"
  gem "rspec"
  gem "rspec-rails"
  gem "rubocop-govuk"
  gem "simplecov"
  gem "timecop"
  gem "webdrivers"
  gem "webmock"
end
