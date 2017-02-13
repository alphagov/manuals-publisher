class RepublishManualService
  def initialize(published_listeners: [], draft_listeners: [], manual_id:)
    @published_listeners = published_listeners
    @draft_listeners = draft_listeners
    @manual_id = manual_id
  end

  def call
    notify_published_listeners if manual_versions[:published].present?
    notify_draft_listeners if manual_versions[:draft].present?

    manual_versions
  end

private
  attr_reader :published_listeners, :draft_listeners, :manual_id

  def manual_repository
    VersionedManualRepository
  end

  def notify_published_listeners
    published_listeners.each { |l| l.call(manual_versions[:published], :republish) }
  end

  def notify_draft_listeners
    draft_listeners.each { |l| l.call(manual_versions[:draft], :republish) }
  end

  def manual_versions
    @manual_versions ||= manual_repository.get_manual(manual_id)
  rescue ManualRepository::NotFoundError => error
    raise ManualNotFoundError.new(error)
  end

  class ManualNotFoundError < StandardError; end
end
