class PublishingAdapter
  def save(manual, action = nil)
    PublishingApiDraftManualWithSectionsExporter.new.call(manual, action)
  end
end
