require "adapters"

class Manual::RedirectService
  def initialize(user:, manual_id:, alternative_path:)
    @user = user
    @manual_id = manual_id
    @alternative_path = alternative_path
  end

  def call
    begin
      manual = Manual.find(manual_id, user)
    rescue KeyError => e
      raise ManualNotFoundError, e
    end

    manual.remove

    if manual.removed?
      manual.save!(user)
      Adapters.publishing.redirect(manual, alternative_path)
    end

    manual
  end

private

  attr_reader :user, :manual_id

  class ManualNotFoundError < StandardError; end
end
