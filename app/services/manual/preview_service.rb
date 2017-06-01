class Manual::PreviewService
  def initialize(user:, manual_id:, attributes:)
    @user = user
    @manual_id = manual_id
    @attributes = attributes
  end

  def call
    manual = if manual_id
               Manual.find(manual_id, user)
             else
               Manual.new(attributes)
             end
    manual.update(attributes)
    manual
  end

private

  attr_reader :user, :manual_id, :attributes
end
