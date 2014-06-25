require "delegate"
require "active_support/core_ext/hash"

class SpecialistDocumentHeaderExtractor < SimpleDelegator
  def initialize(doc, parser = Govspeak::Document)
    @parser = parser
    super(doc)
  end

  def headers
    parser.new(doc.body).structured_headers
  end

  def attributes
    {
      headers: headers.map(&:to_h),
    }.merge(doc.attributes)
  end

private
  attr_reader :parser

  def doc
    __getobj__
  end
end
