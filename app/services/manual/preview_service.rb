class Manual::PreviewService
  def initialize(manual_id:, attributes:, user:)
    @manual_id = manual_id
    @attributes = attributes
    @user = user
  end

  def call
    manual.update(attributes)

    ManualPresenter.new(manual)
  end

private

  attr_reader(
    :manual_id,
    :attributes,
    :user,
  )

  def manual
    manual_id ? existing_manual : ephemeral_manual
  end

  def ephemeral_manual
    Manual.new(
      attributes.reverse_merge(
        title: ""
      )
    )
  end

  def existing_manual
    @existing_manual ||= Manual.find(manual_id, user)
  end
end
