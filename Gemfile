source "https://rubygems.org"

gem "rails", "~> 5.2"

# Alphabetical order please :)
gem "gds-sso"
gem "generic_form_builder"
gem "govuk_admin_template"
gem "govuk_sidekiq", "~> 3"
gem "mongoid", "~> 6.0"
gem "mongoid_rails_migrations", git: "https://github.com/alphagov/mongoid_rails_migrations", branch: "avoid-calling-bundler-require-in-library-code-v1.1.0-plus-mongoid-v5-fix"
gem "plek"
gem "raindrops", ">= 0.13.0" # we need a version > 0.13.0 for ruby 2.2
gem "state_machine", "1.2.0"

gem "govuk_app_config", "~> 2.0"

if ENV["API_DEV"]
  gem "gds-api-adapters", path: "../gds-api-adapters"
else
  gem "gds-api-adapters", "~> 63.3"
end

if ENV["GOVSPEAK_DEV"]
  gem "govspeak", path: "../govspeak"
else
  gem "govspeak", "~> 6.5.2"
end

gem "govuk_frontend_toolkit", "8.2.0" # we rely on this for correctly previewing govspeak (including interactive elements) - to help with that keep it in sync with the version used in manuals-frontend
gem "sass-rails"
gem "uglifier", ">= 1.3.0"

group :development do
  gem "better_errors"
  gem "binding_of_caller"
end

group :development, :test do
  gem "awesome_print"
  gem "jasmine-rails"
  gem "pry-byebug"
end

group :test do
  gem "cucumber", "~> 3.1.2"
  gem "cucumber-rails", require: false
  gem "database_cleaner"
  gem "factory_bot_rails"
  gem "govuk-content-schema-test-helpers", "1.6.1"
  gem "govuk_test"
  gem "launchy"
  gem "rails-controller-testing"
  gem "rspec"
  gem "rspec-rails"
  gem "rubocop-govuk"
  gem "simplecov"
  gem "timecop"
  gem "webmock"
end
