require "logger"

desc "Update organisation of a Manual"
task :update_manual_organisation, %i[manual_base_path organisation_slug] => :environment do |_, args|
  logger = Logger.new($stdout)
  logger.formatter = Logger::Formatter.new

  manual_base_path = args[:manual_base_path] # e.g. "/guidance/capital-funding-guide"
  organisation_slug = args[:organisation_slug] # e.g. "homes-england"

  logger.info "Looking up Manual content_id from base path (#{manual_base_path})"
  manual_id = Services.publishing_api.lookup_content_id(base_path: manual_base_path, with_drafts: true)
  logger.info "- found: #{manual_base_path} => #{manual_id}"

  logger.info "Looking up organisation content_id from organisation slug (#{organisation_slug})"
  organisation_id = Services.publishing_api.lookup_content_id(
    base_path: "/government/organisations/#{organisation_slug}",
  )
  logger.info "- found: #{organisation_slug} => #{organisation_id}"

  # Update the record in the local database to allow the members of the
  # given organisation to access the manual in Manuals Publisher
  logger.info "Updating record in local database"
  manual_record = ManualRecord.find_by(manual_id:)
  manual_record.update!(organisation_slug:)
  section_content_ids = manual_record.latest_edition.section_uuids

  # Use the Publishing API to update the document
  # across GOV.UK and front end applications
  logger.info "Updating organisations links in Publishing API"
  [manual_id, *section_content_ids].each do |content_id|
    logger.info " - Updateing content item #{content_id}"
    Services.publishing_api.patch_links(content_id, links: { organisations: [organisation_id], primary_publishing_organisation: [organisation_id] })
  end

  logger.info "Complete. Updated organisation for '#{manual_base_path}' to '#{organisation_slug}'"
end
