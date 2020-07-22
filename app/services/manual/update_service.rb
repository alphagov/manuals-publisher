require "adapters"

class Manual::UpdateService
  def initialize(user:, manual_id:, attributes:)
    @user = user
    @manual_id = manual_id
    @attributes = attributes
  end

  def call
    manual = Manual.find(manual_id, user)

    manual.draft
    manual.assign_attributes(attributes)
    manual.save!(user)
    reloaded_manual = Manual.find(manual.id, user)
    Adapters.publishing.save_draft(reloaded_manual)

    manual
  end

private

  attr_reader :user, :manual_id, :attributes
end
