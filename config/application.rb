require File.expand_path("../boot", __FILE__)

require "action_controller/railtie"
require "action_mailer/railtie"
require "sprockets/railtie"

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(:default, Rails.env)
Bundler.require(*Rails.groups(assets: %w(development test)))

module ManualsPublisher
  class Application < Rails::Application
    # Settings in config/environments/* take precedence over those specified here.
    # Application configuration should go into files in config/initializers
    # -- all .rb files in that directory are automatically loaded.

    # Set Time.zone default to the specified zone and make Active Record auto-convert to this zone.
    # Run "rake -D time" for a list of tasks for finding time zone names. Default is UTC.
    # config.time_zone = 'Central Time (US & Canada)'

    # The default locale is :en and all translations from config/locales/*.rb,yml are auto loaded.
    # config.i18n.load_path += Dir[Rails.root.join('my', 'locales', '*.{rb,yml}').to_s]
    # config.i18n.default_locale = :de

    # Enable the asset pipeline
    config.assets.enabled = true
    config.assets.initialize_on_precompile = true

    # These paths are non-standard (they are subdirectories of
    # app/models) so they need to be added to the autoload_paths
    config.autoload_paths << "#{Rails.root}/app/exporters/formatters"
    config.autoload_paths << "#{Rails.root}/app/models/builders"
    config.autoload_paths << "#{Rails.root}/app/models/validators"
    config.autoload_paths << "#{Rails.root}/app/repositories/marshallers"
    config.autoload_paths << "#{Rails.root}/app/services/manual"
    config.autoload_paths << "#{Rails.root}/app/services/section"
    config.autoload_paths << "#{Rails.root}/app/services/attachment"
  end
end
