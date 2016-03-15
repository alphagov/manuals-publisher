namespace :publishing_api do
  desc "Publish all Finders to the Publishing API"
  task :publish_finders => :environment do
    require "publishing_api_finder_publisher"
    require "publishing_api_finder_loader"

    finder_loader = PublishingApiFinderLoader.new

    PublishingApiFinderPublisher.new(finder_loader.finders).call
  end

  # Find the manual by base_path from content store.
  # Publish a redirect for the manual.
  # Iterate through links[sections], publish a redirect per section.
  desc "Redirect manual and sections"
  task :redirect_manual_and_sections, [:base_path, :destination] => :environment do |task, args|
    ManualAndSectionsRedirecter.new(
      base_path: args[:base_path],
      destination: args[:destination]
    ).redirect
  end
end
