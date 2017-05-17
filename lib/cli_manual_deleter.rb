require "adapters"

class CliManualDeleter
  def initialize(manual_slug: nil, manual_id: nil, stdin: STDIN, stdout: STDOUT)
    unless manual_slug || manual_id
      raise ArgumentError.new("manual_slug or manual_id must be supplied")
    end
    if manual_slug && manual_id
      raise ArgumentError.new("manual_slug and manual_id must not both be supplied")
    end
    @manual_slug = manual_slug
    @manual_id = manual_id
    @stdin = stdin
    @stdout = stdout
  end

  def call
    manual_record = find_manual_record
    manual = Manual.build_manual_for(manual_record)

    user_must_confirm(manual)

    complete_removal(manual)
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
    unless records.any?
      if manual_id
        raise "No manual found for ID: #{manual_id}"
      else
        raise "No manual found for slug: #{manual_slug}"
      end
    end
    if records.size > 1
      if manual_id
        raise "Ambiguous ID: #{manual_id}"
      else
        raise "Ambiguous slug: #{manual_slug}"
      end
    end
  end

  def validate_never_published(manual_record)
    unless manual_record.editions.all? { |e| e.state == "draft" }
      raise "Cannot delete; is published or has been previously published."
    end
  end

  def user_must_confirm(manual)
    number_of_sections = manual.sections.count
    log "### PLEASE CONFIRM -------------------------------------"
    log "Manual to be deleted: #{manual.slug}"
    log "Organisation: #{manual.organisation_slug}"
    log "This manual has #{number_of_sections} sections, and was last edited at #{manual.updated_at}"
    log "Type 'y' to proceed and delete this manual or anything else to exit:"

    response = stdin.gets
    unless response.strip.casecmp("y").zero?
      raise "Quitting"
    end
  end

  def complete_removal(manual)
    Adapters.publishing.discard(manual)

    manual.destroy

    log "Manual destroyed."
    log "--------------------------------------------------------"
  rescue GdsApi::HTTPNotFound
    log "Draft for #{manual.id} or its sections already discarded."
  end

  def log(message)
    stdout.puts(message)
  end
end
