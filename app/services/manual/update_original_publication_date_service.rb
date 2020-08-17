require "adapters"

class Manual::UpdateOriginalPublicationDateService
  def initialize(user:, manual_id:, attributes:)
    @user = user
    @manual_id = manual_id
    @attributes = attributes.slice(:originally_published_at, :use_originally_published_at_for_public_timestamp)
  end

  def call
    manual = Manual.find(manual_id, user)

    manual.draft
    manual.assign_attributes(attributes)
    manual.sections.each do |section|
      # a nil change note will omit this update from publication logs
      section.assign_attributes(change_note: nil)
    end
    manual.save!(user)
    manual = Manual.find(manual_id, user)

    Adapters.publishing.save_draft(manual)

    manual
  end

private

  attr_reader :user, :manual_id, :attributes
end
