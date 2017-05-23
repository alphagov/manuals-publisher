require "adapters"

class Manual::UpdateOriginalPublicationDateService
  def initialize(user:, manual_id:, attributes:)
    @user = user
    @manual_id = manual_id
    @attributes = attributes.slice(:originally_published_at, :use_originally_published_at_for_public_timestamp)
  end

  def call
    manual.draft
    update
    update_sections
    persist

    export_draft_to_publishing_api

    manual
  end

private

  attr_reader :user, :manual_id, :attributes

  def update
    manual.update(attributes)
  end

  def persist
    manual.save(user)
    @manual = fetch_manual
  end

  def manual
    @manual ||= fetch_manual
  end

  def update_sections
    manual.sections.each do |section|
      # a nil change note will omit this update from publication logs
      section.update(change_note: nil)
    end
  end

  def export_draft_to_publishing_api
    Adapters.publishing.save(manual)
  end

  def fetch_manual
    Manual.find(manual_id, user)
  end
end
