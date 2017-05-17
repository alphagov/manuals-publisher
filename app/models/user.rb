require "gds-sso/user"

class User
  include Mongoid::Document
  include Mongoid::Timestamps
  include GDS::SSO::User

  store_in collection: :manuals_publisher_users

  field :uid, type: String
  field :email, type: String
  field :version, type: Integer
  field :name, type: String
  field :permissions, type: Array
  field :remotely_signed_out, type: Boolean, default: false
  field :organisation_slug, type: String
  field :organisation_content_id, type: String
  field :disabled, type: Boolean, default: false

  def self.gds_editor
    User.new.tap do |user|
      user.permissions = [PermissionChecker::GDS_EDITOR_PERMISSION]
    end
  end

  def manual_records
    permission_checker = PermissionChecker.new(self)
    if permission_checker.is_gds_editor?
      ManualRecord.all
    else
      ManualRecord.where(organisation_slug: organisation_slug)
    end
  end
end
