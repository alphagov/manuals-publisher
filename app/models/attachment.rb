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
    previous_file_id = file_id
    response = Services.attachment_api.create_asset(file: @uploaded_file, draft: true)
    new_file_id = response["id"].split("/").last

    Services.attachment_api.update_asset(previous_file_id, replacement_id: new_file_id) if previous_file_id.present?

    self.file_id = new_file_id
    self.file_url = response["file_url"]
    @file_has_changed = false
  end

  def publish_file
    return if file_id.blank?

    Services.attachment_api.update_asset(file_id, draft: false)
  end

  def content_type
    return unless file_url

    extname = File.extname(file_url).delete(".")
    "application/#{extname}"
  end
end
