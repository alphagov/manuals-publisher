class ViewAdapterRegistry
  def for_document(document)
    get(document.document_type).new(document)
  end

private
  VIEW_ADAPTER_MAP = {}.freeze

  def get(type)
    VIEW_ADAPTER_MAP.fetch(type)
  end
end
