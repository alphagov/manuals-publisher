require "delegate"
require "active_support/core_ext/hash"

class SectionHeaderExtractor < SimpleDelegator
  def self.create
    ->(section) {
      SectionHeaderExtractor.new(
        GovspeakHeaderExtractor.new,
        section,
      )
    }
  end

  def initialize(header_parser, section)
    @header_parser = header_parser
    super(section)
  end

  def headers
    header_parser.call(section.body)
  end

  def serialized_headers
    headers.map(&:to_h)
  end

  def attributes
    {
      headers: serialized_headers,
    }.merge(section.attributes)
  end

private

  attr_reader(
    :header_parser,
  )

  def section
    __getobj__
  end
end
