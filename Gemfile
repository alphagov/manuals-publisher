source "https://rubygems.org"

gem "rails", "7.1.4"

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
gem "sentry-sidekiq"
gem "state_machines"
gem "state_machines-mongoid"
gem "uglifier"

group :development, :test do
  gem "govuk_test"
  gem "listen"
  gem "pry-byebug"
end

group :test do
  gem "cucumber", require: false
  gem "cucumber-rails", "~> 3.0", require: false # specified to prevent regression via Cucumber 8
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
