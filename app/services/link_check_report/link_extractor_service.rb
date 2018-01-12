require "govspeak/link_extractor"

class LinkCheckReport::LinkExtractorService
  def initialize(body:)
    @body = body
  end

  def call
    govspeak_document.extracted_links(website_root: website_root)
  end

private

  attr_reader :body

  def website_root
    @website_root ||= Plek.new.website_root
  end

  def govspeak_document
    Govspeak::Document.new(body)
  end
end
