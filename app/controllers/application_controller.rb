require "forwardable"
require "permission_checker"

class ApplicationController < ActionController::Base
  include GDS::SSO::ControllerMethods
  extend Forwardable

  before_filter :require_signin_permission!
  before_filter :set_authenticated_user_header

  protect_from_forgery with: :exception

  rescue_from("ManualRepository::NotFoundError") do
    redirect_to(manuals_path, flash: { error: "Manual not found" })
  end

  def current_user_can_edit?(format)
    permission_checker.can_edit?(format)
  end
  helper_method :current_user_can_edit?

  def current_user_can_publish?(format)
    permission_checker.can_publish?(format)
  end
  helper_method :current_user_can_publish?

  def current_user_can_withdraw?(format)
    permission_checker.can_withdraw?(format)
  end
  helper_method :current_user_can_withdraw?

  def current_user_is_gds_editor?
    permission_checker.is_gds_editor?
  end
  helper_method :current_user_is_gds_editor?

  def current_organisation_slug
    current_user.organisation_slug
  end

  def permission_checker
    @permission_checker ||= PermissionChecker.new(current_user)
  end

  def set_authenticated_user_header
    if current_user && GdsApi::GovukHeaders.headers[:x_govuk_authenticated_user].nil?
      GdsApi::GovukHeaders.set_header(:x_govuk_authenticated_user, current_user.uid)
    end
  end
end
