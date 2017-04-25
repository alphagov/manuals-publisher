class VersionedManualRepository
  def get_current_draft_version_of_manual(manual_record)
    return nil unless manual_record.latest_edition.state == "draft"

    Manual.build_manual_for(manual_record)
  end

  def get_current_published_version_of_manual(manual_record)
    return nil unless manual_record.has_ever_been_published?

    if manual_record.latest_edition.state == "published"
      Manual.build_manual_for(manual_record)
    elsif manual_record.latest_edition.state == "draft"
      previous_edition = manual_record.editions.order_by([:version_number, :desc]).limit(2).last
      if previous_edition.state == "published"
        Manual.build_manual_for(manual_record, edition: previous_edition).tap do |manual|
          manual.sections = get_published_version_of_sections(previous_edition.section_ids)
        end
      else
        # This means the previous edition is withdrawn so we shouldn't
        # expose it as it's not actually published (we've got a new
        # draft waiting in the wings for a withdrawn manual)
        return nil
      end
    else
      # This means the current edition is withdrawn so we shouldn't find
      # the previously published one
      return nil
    end
  end

private

  def get_published_version_of_sections(section_ids)
    (section_ids || []).map do |section_id|
       editions = SectionEdition
         .where(section_id: section_id)
         .order_by([:version_number, :desc])
         .to_a
         .drop_while { |e| e.state != "published" }
         .take(2)
         .reverse
       Section.new(
         ->(_title) { raise RuntimeError, "read only manual" },
         section_id,
         editions,
       )
    end
  end
end
