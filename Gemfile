source "https://rubygems.org"

gem "rails", "3.2.22.3"

# Alphabetical order please :)
gem "airbrake", "~> 4.3"
gem "bson_ext", "1.12.1"
gem "faraday", "0.9.0"
gem "fetchable", "1.0.0"
gem "gds-sso", "~> 11.0" # can't go higher because govuk_content_models needs this version (also > 12 need rails 4+)
gem "generic_form_builder", "0.11.0"
gem "govuk_admin_template", "~> 4.0" # higher versions require rails 4
gem "kaminari", "0.16.1"
gem "logstasher", "0.4.8"
gem "mongoid", "~> 2.5"
gem "mongoid_rails_migrations", git: "https://github.com/alphagov/mongoid_rails_migrations", branch: "avoid-calling-bundler-require-in-library-code"
gem "multi_json", "1.10.0"
gem "plek", "1.12.0"
gem "quiet_assets", "1.0.3"
gem "raindrops", ">= 0.13.0" # we need a version > 0.13.0 for ruby 2.2
gem "rack", "~> 1.4.6" # explicitly requiring patched version re: CVE-2015-3225
gem "rake", "< 12.0.0" # versions newer than this break in rails 3.2
gem "sidekiq", "3.2.1"
gem "sidekiq-statsd", "0.1.5"
gem "state_machine", "1.2.0"
gem "unicorn", "4.8.2"

# We only need this for tests and rails 3.2 and ruby 2.2
# however, it can't be in a gem group that isn't installed
# on production environments or the console won't load
gem 'test-unit', require: false

if ENV["API_DEV"]
  gem "gds-api-adapters", path: "../gds-api-adapters"
else
  gem "gds-api-adapters", "~> 39.0"
end

if ENV["GOVSPEAK_DEV"]
  gem "govspeak", path: "../govspeak"
else
  gem "govspeak", "~> 3.1" # can't go higher because govuk_content_models needs this
end

group :assets do
  gem "govuk_frontend_toolkit", "1.2.0" # we rely on this for correctly previewing govspeak (including interactive elements) - to help with that keep it in sync with the version used in manuals-frontend
  gem "sass-rails", "3.2.6"
  gem "uglifier", ">= 1.3.0"
end

group :development do
  gem "better_errors"
  gem "binding_of_caller"
end

group :development, :test do
  gem "awesome_print"
  gem "foreman"
  gem "jasmine-rails"
  gem "pry-byebug"
  gem "sinatra"
end

group :test do
  gem "cucumber", "~> 2.2.0"
  gem "cucumber-rails", "~> 1.4.0", require: false
  gem "database_cleaner"
  gem "factory_girl_rails"
  gem "govuk-lint"
  gem "govuk-content-schema-test-helpers", "1.4.0"
  gem "launchy"
  gem "poltergeist", "~> 1.13.0"
  gem "phantomjs", ">= 1.9.7.1"
  gem "rspec", "~> 3.4.0"
  gem "rspec-rails", "~> 3.4.0"
  gem "simplecov"
  gem "timecop"
  gem "webmock"
end
