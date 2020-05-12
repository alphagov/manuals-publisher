require "delegate"

class MarkdownAttachmentProcessor < SimpleDelegator
  def body
    attachments.reduce(doc.body) do |body, attachment|
      body.gsub(attachment.snippet) do
        attachment_markdown(attachment)
      end
    end
  end

private

  def attachment_markdown(attachment)
    "[#{attachment.title}](#{attachment.file_url})"
  end

  def doc
    __getobj__
  end
end
