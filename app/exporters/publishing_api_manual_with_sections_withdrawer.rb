class PublishingApiManualWithSectionsWithdrawer
  def call(manual, _ = nil)
    Services.publishing_api.unpublish(manual.id, type: "gone")

    manual.sections.each do |section|
      Services.publishing_api.unpublish(section.uuid, type: "gone")
    end
  end
end
