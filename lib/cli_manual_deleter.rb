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
    manual = find_manual

    complete_removal(manual)
  end

private

  attr_reader :manual_slug, :manual_id, :stdin, :stdout

  def find_manual
    user = User.gds_editor
    manual = if manual_id
               Manual.find(manual_id, user)
             else
               Manual.find_by_slug!(manual_slug, user)
             end

    validate_never_published(manual)
    manual
  end

  def validate_never_published(manual)
    unless manual.editions.all? { |e| e.state == "draft" }
      raise "Cannot delete; is published or has been previously published."
    end
  end

  def complete_removal(manual)
    begin
      Adapters.publishing.discard(manual)
    rescue GdsApi::HTTPNotFound
      log "Draft for #{manual.id} or its sections already discarded."
    end

    manual.destroy

    log "Manual destroyed."
    log "--------------------------------------------------------"
  end

  def log(message)
    stdout.puts(message)
  end
end
