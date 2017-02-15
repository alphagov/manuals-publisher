# Autoload the User model from govuk_content_models
require 'user'

# We need to add this field to User as the rebuild uses it for permissions.
class User
  field "organisation_content_id", type: String
end
