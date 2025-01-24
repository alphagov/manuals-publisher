source "https://rubygems.org"

gem "rails", "8.0.1"

gem "bootsnap", require: false
gem "dartsass-rails"
gem "gds-api-adapters"
gem "gds-sso"
gem "generic_form_builder"
gem "govspeak"
gem "govuk_app_config"
gem "govuk_publishing_components"
gem "govuk_sidekiq"
gem "mongoid"
gem "plek"
# TODO: remove after next version of Puma is released
# See https://github.com/puma/puma/pull/3532
# `require: false` is needed because you can't actually `require "rackup"`
# due to a different bug: https://github.com/rack/rackup/commit/d03e1789
gem "rackup", "2.2.1", require: false
gem "sentry-sidekiq"
gem "state_machines"
gem "state_machines-mongoid"
gem "terser"

group :development, :test do
  gem "govuk_test"
  gem "listen"
  gem "pry-byebug"
end

group :test do
  gem "cucumber", require: false
  gem "cucumber-rails", "~> 3.1", require: false # specified to prevent regression via Cucumber 8
  gem "database_cleaner-mongoid"
  gem "factory_bot_rails"
  gem "govuk_schemas"
  gem "rails-controller-testing"
  gem "rspec"
  gem "rspec-rails"
  gem "rubocop-govuk"
  gem "simplecov"
  gem "webmock"
end
