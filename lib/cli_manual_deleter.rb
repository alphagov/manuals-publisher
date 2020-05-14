require "adapters"

class CliManualDeleter
  def initialize(manual_slug: nil, manual_id: nil, stdin: STDIN, stdout: STDOUT)
    unless manual_slug || manual_id
      raise ArgumentError, "manual_slug or manual_id must be supplied"
    end
    if manual_slug && manual_id
      raise ArgumentError, "manual_slug and manual_id must not both be supplied"
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

  def user
    @user ||= User.gds_editor
  end

  def find_manual
    manual = if manual_id
               Manual.find(manual_id, user)
             else
               Manual.find_by_slug!(manual_slug, user)
             end
    manual
  end

  def complete_removal(manual)
    service = Manual::DiscardDraftService.new(user: user, manual_id: manual.id)

    result = service.call
    if result.successful?
      log "Manual destroyed."
      log "--------------------------------------------------------"
    else
      raise "Cannot delete; is published or has been previously published."
    end
  end

  def log(message)
    stdout.puts(message)
  end
end
