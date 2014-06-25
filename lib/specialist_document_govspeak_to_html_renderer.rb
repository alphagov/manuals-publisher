require "delegate"

class SpecialistDocumentGovspeakToHTMLRenderer < SimpleDelegator
  def initialize(document, converter = Govspeak::Document)
    @document = document
    @converter = converter
    super(document)
  end

  def body
    converter.new(document.body).to_html
  end

  def attributes
    document.attributes.merge(
      body: body,
    )
  end

private
  attr_reader :converter, :document
end
