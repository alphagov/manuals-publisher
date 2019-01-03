require "services"

class Attachment
  include Mongoid::Document
  include Mongoid::Timestamps

  field :title
  field :filename
  field :file_id, type: String
  field :file_url, type: String

  embedded_in :section_edition

  before_save :upload_file, if: :file_has_changed?

  def to_param
    id.to_s
  end

  def snippet
    "[InlineAttachment:#{filename}]"
  end

  def file=(file)
    @file_has_changed = true
    @uploaded_file = file
  end

  def file_has_changed?
    @file_has_changed
  end

  def upload_file
    if file_id.nil?
      response = Services.attachment_api.create_asset(file: @uploaded_file)
      self.file_id = response["id"].split("/").last
    else
      response = Services.attachment_api.update_asset(file_id, file: @uploaded_file)
    end
    self.file_url = response["file_url"]
  rescue GdsApi::HTTPNotFound => e
    raise "Error uploading file. Is the Asset Manager service available?\n#{e.message}"
  rescue StandardError
    errors.add(:file_id, "could not be uploaded")
  end

  def content_type
    return unless file_url

    extname = File.extname(file_url).delete(".")
    "application/#{extname}"
  end
end
