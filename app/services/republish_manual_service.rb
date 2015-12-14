require "tag_fetcher"

class RepublishManualService
  def initialize(manual_repository:, listeners: [], manual_id:)
    @manual_repository = manual_repository
    @listeners = listeners
    @manual_id = manual_id
  end

  def call
    if manual.published?
      update_manual_with_tags
      notify_listeners
    end

    manual
  end

private
  attr_reader :manual_repository, :listeners, :manual_id

  def notify_listeners
    update_manual_with_tags
    listeners.each { |l| l.call(manual) }
  end

  def manual
    @manual ||= manual_repository.fetch(manual_id)
  rescue KeyError => error
    raise ManualNotFoundError.new(error)
  end

  def tags
    TagFetcher.new(manual).tags.map { |t|
      {
        type: t.details.type,
        slug: t.slug,
      }
    }
  end

  def update_manual_with_tags
    manual.update({tags: tags})
  end

  class ManualNotFoundError < StandardError; end
end
