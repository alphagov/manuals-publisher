class Manual::ListService
  def initialize(user:)
    @user = user
  end

  def call
    Manual.all(user, load_associations: false)
  end

private

  attr_reader :user
end
