require "adapters"

class Manual::CreateService
  def initialize(user:, attributes:)
    @user = user
    @attributes = attributes
  end

  def call
    manual = Manual.new(attributes)

    if manual.valid?
      manual.save(user)
      Adapters.publishing.save(manual)
    end

    manual
  end

private

  attr_reader :user, :attributes
end
