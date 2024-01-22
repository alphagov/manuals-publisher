APP_STYLESHEETS = {
  "application.scss" => "application.css",
}.freeze

all_stylesheets = APP_STYLESHEETS.merge(GovukPublishingComponents::Config.all_stylesheets)
Rails.application.config.dartsass.builds = all_stylesheets

Rails.application.config.dartsass.build_options << " --quiet-deps"

# Maintain Rails < 7 behaviour of running yarn:install before assets:precompile
Rake::Task["assets:precompile"].enhance(["yarn:install"]).enhance(["dartsass:build"])
