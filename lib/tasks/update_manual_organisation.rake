require "logger"

desc "Update organisation of a Manual"
task :update_manual_organisation, %i[manual_base_path organisation_slug] => :environment do |_, args|
  logger = Logger.new(STDOUT)
  logger.formatter = Logger::Formatter.new

  manual_base_path = args[:manual_base_path] # e.g. "/guidance/capital-funding-guide"
  organisation_slug = args[:organisation_slug] # e.g. "homes-england"

  logger.info "Looking up Manual content_id from base path (#{manual_base_path})"
  manual_id = Services.publishing_api.lookup_content_id(base_path: manual_base_path)
  logger.info "- found: #{manual_base_path} => #{manual_id}"

  logger.info "Looking up organisation content_id from organisation slug (#{organisation_slug})"
  organisation_id = Services.publishing_api.lookup_content_id(
    base_path: "/government/organisations/#{organisation_slug}",
  )
  logger.info "- found: #{organisation_slug} => #{organisation_id}"

  # Update the record in the local database to allow the members of the
  # given organisation to access the manual in Manuals Publisher
  logger.info "Updating record in local database"
  ManualRecord.find_by(manual_id: manual_id).update!(organisation_slug: organisation_slug)

  # Use the Publishing API to update the document
  # across GOV.UK and front end applications
  logger.info "Updating organisations links in Publishing API"
  Services.publishing_api.patch_links(manual_id, links: { organisations: [organisation_id] })

  logger.info "Complete. Updated organisation for '#{manual_base_path}' to '#{organisation_slug}'"
end
