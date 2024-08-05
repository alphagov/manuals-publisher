class Manual::CreateService
  def initialize(user:, attributes:)
    @user = user
    @attributes = attributes
  end

  def call
    manual = Manual.new(attributes)

    if manual.valid?
      Publishing::DraftAdapter.save_draft_for_manual_and_sections(manual)
      manual.save!(user)
    end

    manual
  end

private

  attr_reader :user, :attributes
end
