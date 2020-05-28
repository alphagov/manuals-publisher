require_relative "boot"

require "action_controller/railtie"
require "action_mailer/railtie"
require "sprockets/railtie"

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

module ManualsPublisher
  class Application < Rails::Application
    # Initialize configuration defaults for originally generated Rails version.
    config.load_defaults 5.1

    # Settings in config/environments/* take precedence over those specified here.
    # Application configuration should go into files in config/initializers
    # -- all .rb files in that directory are automatically loaded.

    # These paths are non-standard (they are subdirectories of
    # app/models) so they need to be added to the autoload_paths
    config.autoload_paths << Rails.root.join("app/exporters/formatters")
    config.autoload_paths << Rails.root.join("app/models/validators")
    config.autoload_paths << Rails.root.join("app/services/manual")
    config.autoload_paths << Rails.root.join("app/services/section")
    config.autoload_paths << Rails.root.join("app/services/attachment")
  end
end
