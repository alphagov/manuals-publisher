module NavigationHelper
  def navigation_links_internal
    [
      { text: "Manuals", href: manuals_path },
      { text: "What's new", href: whats_new_path },
    ]
  end

  def navigation_links_auth
    [
      { text: current_user.name, href: Plek.external_url_for("signon") },
      { text: "Log out", href: gds_sign_out_path },
    ]
  end
end
