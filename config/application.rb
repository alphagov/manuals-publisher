require_relative "boot"

require "rails"

require "action_controller/railtie"
require "action_mailer/railtie"
require "sprockets/railtie"

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

module ManualsPublisher
  class Application < Rails::Application
    # Initialize configuration defaults for originally generated Rails version.
    config.load_defaults 6.0

    # Settings in config/environments/* take precedence over those specified here.
    # Application configuration can go into files in config/initializers
    # -- all .rb files in that directory are automatically loaded after loading
    # the framework and any gems in your application.

    # Using a sass css compressor causes a scss file to be processed twice
    # (once to build, once to compress) which breaks the usage of "unquote"
    # to use CSS that has same function names as SCSS such as max.
    # https://github.com/alphagov/govuk-frontend/issues/1350
    config.assets.css_compressor = nil
  end
end

if defined?(Jasmine)
  Jasmine.configure do |config|
    # existing config here

    if ENV["SELENIUM_URL"]
      # require "socket"
      # ip = Socket.ip_address_list
      #   .detect(&:ipv4_private?)
      #   .ip_address
      config.host = "http://manuals-publisher.dev.gov.uk/"
    end
  end
end
