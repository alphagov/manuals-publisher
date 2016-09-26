ManualsPublisher::Application.configure do
  # Settings specified here will take precedence over those in config/application.rb.

  # In the development environment your application's code is reloaded on
  # every request. This slows down response time but is perfect for development
  # since you don't have to restart the web server when you make code changes.
  config.cache_classes = false

  # Do not eager load code on boot.
  config.eager_load = false

  # Show full error reports and disable caching.
  config.consider_all_requests_local       = true
  config.action_controller.perform_caching = false

  # Don't care if the mailer can't send.
  config.action_mailer.raise_delivery_errors = false

  # Your secret key is used for verifying the integrity of signed cookies.
  # If you change this key, all old signed cookies will become invalid!
  config.secret_token = "87fc5f137cb0c6a93584546b39d88aafcff72955cb2e3ef3d99040c77f52bcff38b26c9056c655f23e07edfcb57ab80315b4b094c50fc30f5321ad361b637a7b"

  # Print deprecation notices to the Rails logger.
  config.active_support.deprecation = :log

  # Debug mode disables concatenation and preprocessing of assets.
  # This option may cause significant delays in view rendering with a large
  # number of complex assets.
  config.assets.debug = true
end
