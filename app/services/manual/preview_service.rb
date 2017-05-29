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
    manual_id ? existing_manual : Manual.new(attributes)
  end

  def existing_manual
    @existing_manual ||= Manual.find(manual_id, user)
  end
end
