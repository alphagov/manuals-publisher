module NavigationHelper
  def navigation_links_internal
    links = [
      { text: "Manuals", href: manuals_path, active: request.path == manuals_path },
    ]
    if Time.zone.today < Date.new(2023, 11, 1)
      links << { text: "What's new", href: whats_new_path, active: request.path == whats_new_path }
    end
    links
  end

  def navigation_links_auth
    [
      { text: current_user.name, href: Plek.external_url_for("signon") },
      { text: "Log out", href: gds_sign_out_path },
    ]
  end
end
