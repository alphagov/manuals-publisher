require "adapters"

class Manual::CreateService
  def initialize(attributes:, user:)
    @attributes = attributes
    @user = user
  end

  def call
    if manual.valid?
      persist
      export_draft_to_publishing_api
    end

    manual
  end

private

  attr_reader(
    :attributes,
    :user,
  )

  def manual
    @manual ||= Manual.build(attributes)
  end

  def persist
    manual.save(user)
  end

  def export_draft_to_publishing_api
    reloaded_manual = Manual.find(manual.id, user)
    Adapters.publishing.save(reloaded_manual)
  end
end
