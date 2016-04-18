namespace :publishing_api do
  desc "Publish all Finders to the Publishing API"
  task :publish_finders => :environment do
    require "publishing_api_finder_publisher"
    require "publishing_api_finder_loader"

    finder_loader = PublishingApiFinderLoader.new('finders')

    if finder_loader.metadata_files_missing_schema.any?
      puts "Metadata files without a matching schema: #{finder_loader.metadata_files_missing_schema}"
    end

    if finder_loader.schema_files_missing_metadata.any?
      puts "Schema files without a matching metadata: #{finder_loader.schema_files_missing_metadata}"
    end

    PublishingApiFinderPublisher.new(finder_loader.finders).call
  end
end
