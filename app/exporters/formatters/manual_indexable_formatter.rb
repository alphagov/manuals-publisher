class ManualIndexableFormatter
  RUMMAGER_DOCUMENT_TYPE = "manual".freeze

  def initialize(manual)
    @manual = manual
  end

  def id
    Pathname.new('/').join(@manual.slug).to_s
  end

  def type
    RUMMAGER_DOCUMENT_TYPE
  end

  def indexable_attributes
    {
      title: @manual.title,
      description: @manual.summary,
      link: Pathname.new('/').join(@manual.slug).to_s,
      indexable_content: @manual.summary,
      public_timestamp: @manual.updated_at,
      content_store_document_type: type,
    }
  end
end
