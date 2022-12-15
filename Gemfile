source "https://rubygems.org"

gem "rails", "7.0.4"

gem "gds-api-adapters"
gem "gds-sso"
gem "generic_form_builder"
gem "govspeak"
gem "govuk_admin_template"
gem "govuk_app_config"
gem "govuk_frontend_toolkit"
gem "govuk_sidekiq"
gem "mail", "~> 2.8.0"  # TODO: remove once https://github.com/mikel/mail/issues/1489 is fixed.
gem "mongoid"
gem "plek"
gem "sass-rails"
gem "sentry-sidekiq"
gem "state_machine"
gem "uglifier"

group :development, :test do
  gem "govuk_test"
  gem "listen"
  gem "pry-byebug"
end

group :test do
  gem "cucumber", require: false
  gem "cucumber-rails", "~> 2.6", require: false # specified to prevent regression via Cucumber 8
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
