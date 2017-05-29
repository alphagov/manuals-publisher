class Manual::PreviewService
  def initialize(user:, manual_id:, attributes:)
    @user = user
    @manual_id = manual_id
    @attributes = attributes
  end

  def call
    manual.update(attributes)

    ManualPresenter.new(manual)
  end

private

  attr_reader :user, :manual_id, :attributes

  def manual
    manual_id ? Manual.find(manual_id, user) : Manual.new(attributes)
  end
end
