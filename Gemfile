source "https://rubygems.org"

gem "rails", "~> 5.1"

# Alphabetical order please :)
gem "gds-sso"
gem "generic_form_builder"
gem "govuk_admin_template"
gem "logstasher", "0.4.8"
gem "mongoid", "~> 6.0"
gem "mongoid_rails_migrations", git: "https://github.com/alphagov/mongoid_rails_migrations", branch: "avoid-calling-bundler-require-in-library-code-v1.1.0-plus-mongoid-v5-fix"
gem "plek"
gem "raindrops", ">= 0.13.0" # we need a version > 0.13.0 for ruby 2.2
gem "sidekiq", "3.2.1"
gem "sidekiq-statsd", "0.1.5"
gem "state_machine", "1.2.0"
gem "unicorn", "4.8.2"

gem "govuk_app_config", "~> 0.2"

if ENV["API_DEV"]
  gem "gds-api-adapters", path: "../gds-api-adapters"
else
  gem "gds-api-adapters", "~> 47.9.1"
end

if ENV["GOVSPEAK_DEV"]
  gem "govspeak", path: "../govspeak"
else
  gem "govspeak", "~> 3.1"
end

gem "govuk_frontend_toolkit", "1.2.0" # we rely on this for correctly previewing govspeak (including interactive elements) - to help with that keep it in sync with the version used in manuals-frontend
gem "sass-rails"
gem "uglifier", ">= 1.3.0"

group :development do
  gem "better_errors"
  gem "binding_of_caller"
end

group :development, :test do
  gem "awesome_print"
  gem "foreman"
  gem "jasmine-rails"
  gem "pry-byebug"
  gem "sinatra", "~> 2.0"
end

group :test do
  gem "cucumber", "~> 2.2.0"
  gem "cucumber-rails", require: false
  gem "database_cleaner"
  gem "factory_girl_rails"
  gem "govuk-lint"
  gem "govuk-content-schema-test-helpers", "1.4.0"
  gem "launchy"
  gem "poltergeist", "~> 1.13.0"
  gem "phantomjs", ">= 1.9.7.1"
  gem "rspec"
  gem "rspec-rails"
  gem "simplecov"
  gem "timecop"
  gem "webmock"
end
