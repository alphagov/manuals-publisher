require "adapters"

class Manual::CreateService
  def initialize(user:, attributes:)
    @user = user
    @attributes = attributes
  end

  def call
    if manual.valid?
      persist
      export_draft_to_publishing_api
    end

    manual
  end

private

  attr_reader :user, :attributes

  def manual
    @manual ||= Manual.new(attributes)
  end

  def persist
    manual.save(user)
  end

  def export_draft_to_publishing_api
    reloaded_manual = Manual.find(manual.id, user)
    Adapters.publishing.save(reloaded_manual)
  end
end
