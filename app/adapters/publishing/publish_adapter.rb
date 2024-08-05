class Publishing::PublishAdapter
  def self.publish_manual_and_sections(manual, republish: false)
    Services.publishing_api.publish(manual.id, update_type(republish))

    manual.sections.each do |section|
      publish_section(section, republish:)
    end

    manual.removed_sections.each do |section|
      Publishing::UnpublishAdapter.unpublish_and_redirect_section(section, redirect: "/#{manual.slug}", republish:)
    end
  end

  private_class_method def self.publish_section(section, republish:)
    if section.needs_exporting? || republish
      Services.publishing_api.publish(section.uuid, update_type(republish))
      section.mark_as_exported! unless republish
    end
  end

  private_class_method def self.update_type(republish)
    republish ? GdsApiConstants::PublishingApi::REPUBLISH_UPDATE_TYPE : nil
  end
end
