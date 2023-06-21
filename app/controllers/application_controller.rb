require "forwardable"
require "permission_checker"

class ApplicationController < ActionController::Base
  include GDS::SSO::ControllerMethods
  extend Forwardable

  protect_from_forgery with: :exception

  before_action :authenticate_user!
  before_action :set_authenticated_user_header

  rescue_from("Manual::NotFoundError") do
    redirect_to(manuals_path, flash: { error: "Manual not found" })
  end

  def preview_design_system?(next_release: false)
    # Temporarily force this flag to 'on' for users in production, regardless of their permissions
    return true if next_release && !Rails.env.test?

    current_user.can_preview_design_system? || (next_release && current_user.can_preview_next_release?)
  end
  helper_method :preview_design_system?

  def render_design_system(design_system_view, legacy_view, locals)
    if get_layout == "design_system"
      render(design_system_view, locals:)
    else
      render legacy_view, locals:
    end
  end

  def current_user_can_publish?
    permission_checker.can_publish?
  end
  helper_method :current_user_can_publish?

  def current_user_can_withdraw?
    permission_checker.can_withdraw?
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
