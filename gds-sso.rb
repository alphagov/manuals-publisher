GDS::SSO.config do |config|
  config.user_model   = "User"
  config.oauth_id     = ENV["OAUTH_ID"] || "not used"
  config.oauth_secret = ENV["OAUTH_SECRET"] || "not used"
  config.oauth_root_url = Plek.current.find("signon")
end
