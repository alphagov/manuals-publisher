RSpec.configure do |config|
  config.include ::Rails::Controller::Testing::TestProcess, type: :controller
  config.include ::Rails::Controller::Testing::TemplateAssertions, type: :controller
  config.include ::Rails::Controller::Testing::Integration, type: :controller
end
