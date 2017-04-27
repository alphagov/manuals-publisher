require "services"

class CliManualDeleter
  def initialize(manual_slug, manual_id: nil, stdin: STDIN, stdout: STDOUT)
    @manual_slug = manual_slug
    @manual_id = manual_id
    @stdin = stdin
    @stdout = stdout
  end

  def call
    manual_record = find_manual_record

    user_must_confirm(manual_record)

    complete_removal(manual_record)
  end

private

  attr_reader :manual_slug, :manual_id, :stdin, :stdout

  def find_manual_record
    manual_records = if manual_id
                       ManualRecord.where(manual_id: manual_id)
                     else
                       ManualRecord.where(slug: manual_slug)
                     end

    validate_manual_records(manual_records)

    manual_records.first.tap do |manual_record|
      validate_never_published(manual_record)
    end
  end

  def validate_manual_records(records)
    raise "No manual found for slug: #{manual_slug}" unless records.any?
    raise "Ambiguous slug: #{manual_slug}" if records.size > 1
  end

  def validate_never_published(manual_record)
    unless manual_record.editions.all? { |e| e.state == "draft" }
      raise "Cannot delete; is published or has been previously published."
    end
  end

  def user_must_confirm(manual_record)
    number_of_sections = section_ids_for(manual_record).count
    log "### PLEASE CONFIRM -------------------------------------"
    log "Manual to be deleted: #{manual_record.slug}"
    log "Organisation: #{manual_record.organisation_slug}"
    log "This manual has #{number_of_sections} sections, and was last edited at #{manual_record.updated_at}"
    log "Type 'y' to proceed and delete this manual or anything else to exit:"

    response = stdin.gets
    unless response.strip.casecmp("y").zero?
      raise "Quitting"
    end
  end

  def section_ids_for(manual_record)
    manual_record.editions.flat_map(&:section_ids).uniq
  end

  # Some of this method violates SRP -- we could move it out to a service if we
  # ever decide to implement a DestroyManualService.  However, to be consistent
  # with other services, it would accept a manual_id, rather than a slug or
  # manual_record. Which we can only obtain here by grabbing a manual record by
  # slug.
  #
  # It would then need to translate the manual_id back into a..manual_record,
  # in order to destroy it. Which we already have available here.
  #
  # I'm loth to do this at this stage, given how specific the requirement
  # driving writing of this script is.
  def complete_removal(manual_record)
    section_ids = section_ids_for(manual_record)

    section_ids.each { |id| discard_draft_from_publishing_api(id) }
    discard_draft_from_publishing_api(manual_record.manual_id)

    section_ids.each do |id|
      SectionEdition.all_for_section(id).map(&:destroy)
    end

    manual_record.destroy

    log "Manual destroyed."
    log "--------------------------------------------------------"
  end

  def log(message)
    stdout.puts(message)
  end

  def discard_draft_from_publishing_api(content_id)
    begin
      Services.publishing_api.discard_draft(content_id)
    rescue GdsApi::HTTPNotFound
      log "Draft for #{content_id} already discarded."
    end
  end
end
