class Publishing::DraftAdapter
  def self.save_draft_for_manual_and_sections(manual, republish: false, include_sections: true, include_links: true)
    PublishingAdapter.save_manual(manual, republish:, include_links:)

    if include_sections
      manual.sections.each do |section|
        PublishingAdapter.save_section(section, manual, republish:, include_links:)
      end
    end
  end
end
