$LOAD_PATH << File.join(File.dirname(__FILE__), "..")

require "simplecov"
SimpleCov.start

# This file is copied to spec/ when you run 'rails generate rspec:install'
ENV["RAILS_ENV"] ||= "test"
require File.expand_path("../../config/environment", __FILE__)
# Prevent database truncation if the environment is production
abort("The Rails environment is running in production mode!") if Rails.env.production?

require "rspec/rails"
require "spec_helper"
require "webmock/rspec"

Dir[Rails.root.join("spec/support/**/*.rb")].each { |f| require f }
Dir[Rails.root.join("features/support/**/*_helpers.rb")]
.reject { |f| f =~ %r{/api_helpers.rb$} }
.each { |f| require f }

require "database_cleaner"
DatabaseCleaner.strategy = :truncation
DatabaseCleaner.clean

RSpec.configure do |config|
  config.before(:each, type: :feature) do
    stub_rummager
    stub_publishing_api
    stub_email_alert_api
  end

  config.include Capybara::DSL, type: :feature

  config.after(:each) do
    DatabaseCleaner.clean
  end
end
