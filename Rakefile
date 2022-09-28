# Add your own tasks in files placed in lib/tasks ending in .rake,
# for example lib/tasks/capistrano.rake, and they will automatically be available to Rake.

require File.expand_path("config/application", __dir__)

ManualsPublisher::Application.load_tasks

# clear existing default task before defining a new one to avoid extending it
Rake::Task[:default].clear if Rake::Task.task_defined?(:default)

task default: %w[
  lint
  jasmine
  spec
  cucumber
]
