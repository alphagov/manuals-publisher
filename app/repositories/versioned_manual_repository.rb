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
      previous_edition = manual_record.previous_edition
      if previous_edition.state == "published"
        Manual.build_manual_for(manual_record, edition: previous_edition, published: true)
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
end
