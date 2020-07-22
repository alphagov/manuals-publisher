require "warden/test/helpers"

module GdsSsoHelpers
  include Warden::Test::Helpers

  def login_as(user_type)
    user = FactoryBot.create(user_type.to_sym) # rubocop:disable Rails/SaveBang
    GDS::SSO.test_user = user
    super(user) # warden
  end

  def log_out
    Capybara.reset_session!
    GDS::SSO.test_user = nil
    logout # warden
  end
end

RSpec.configuration.include GdsSsoHelpers, type: :feature
World(GdsSsoHelpers) if respond_to?(:World)
