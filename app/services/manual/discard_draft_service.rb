require "adapters"

class Manual::DiscardDraftService
  def initialize(user:, manual_id:)
    @user = user
    @manual_id = manual_id
  end

  def call
    manual = Manual.find(manual_id, user)

    if manual.has_ever_been_published?
      Result.failure(manual)
    else
      begin
        Adapters.publishing.discard(manual)
      rescue GdsApi::HTTPNotFound
        # this is fine, the manual has already been discarded from the
        # publishing API and the next line will clean it up in our DB
      end

      manual.destroy!
      Result.success(manual)
    end
  end

private

  attr_reader :user, :manual_id

  class Result
    def self.success(manual)
      new(successful: true, manual: manual)
    end

    def self.failure(manual)
      new(successful: false, manual: manual)
    end

    def initialize(successful:, manual:)
      @successful = successful
      @manual = manual
    end

    def successful?
      @successful
    end

    def manual_title
      @manual.title
    end
  end
end
