require "manual_repository"

class VersionedManualRepository
  class NotFoundError < StandardError; include ManualRepository::NotFoundError; end

  def self.get_manual(manual_id)
    new.get_manual(manual_id)
  end

  def get_manual(manual_id)
    manual_record = ManualRecord.find_by(manual_id: manual_id)
    raise NotFoundError if manual_record.nil?

    {
      draft: get_current_draft_version_of_manual(manual_record),
      published: get_current_published_version_of_manual(manual_record),
    }
  end

private

  def get_current_draft_version_of_manual(manual_record)
    return nil unless manual_record.latest_edition.state == "draft"

    build_manual_for(manual_record, manual_record.latest_edition) do
      {
        sections: get_latest_version_of_sections(manual_record.latest_edition.section_ids),
        removed_sections: get_latest_version_of_sections(manual_record.latest_edition.removed_section_ids),
      }
    end
  end

  def get_current_published_version_of_manual(manual_record)
    return nil unless manual_record.has_ever_been_published?

    if manual_record.latest_edition.state == "published"
      build_manual_for(manual_record, manual_record.latest_edition) do
        {
          sections: get_latest_version_of_sections(manual_record.latest_edition.section_ids),
          removed_sections: get_latest_version_of_sections(manual_record.latest_edition.removed_section_ids),
        }
      end
    elsif manual_record.latest_edition.state == "draft"
      previous_edition = manual_record.editions.order_by([:version_number, :desc]).limit(2).last
      if previous_edition.state == "published"
        build_manual_for(manual_record, previous_edition) do
          {
            sections: get_published_version_of_sections(previous_edition.section_ids),
            removed_sections: get_latest_version_of_sections(previous_edition.removed_section_ids)
          }
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

  def build_manual_for(manual_record, edition)
    base_manual = Manual.new(
      id: manual_record.manual_id,
      slug: manual_record.slug,
      title: edition.title,
      summary: edition.summary,
      body: edition.body,
      organisation_slug: manual_record.organisation_slug,
      state: edition.state,
      version_number: edition.version_number,
      updated_at: edition.updated_at,
      ever_been_published: manual_record.has_ever_been_published?,
      originally_published_at: edition.originally_published_at,
      use_originally_published_at_for_public_timestamp: edition.use_originally_published_at_for_public_timestamp,
    )

    section_attrs = yield

    ManualWithSections.new(
      ->(_manual, _attrs) { raise RuntimeError, "read only manaul" },
      base_manual,
      section_attrs
    )
  end

  def get_latest_version_of_sections(section_ids)
    (section_ids || []).map do |section_id|
      build_section(section_id) { |editions| editions }
    end
  end

  def build_section(section_id)
    all_editions = SectionEdition.where(document_id: section_id).order_by([:version_number, :desc]).to_a
    Section.new(
      ->(_title) { raise RuntimeError, "read only manual" },
      section_id,
      yield(all_editions).take(2).reverse,
    )
  end

  def get_published_version_of_sections(section_ids)
    (section_ids || []).map do |section_id|
      build_section(section_id) { |editions| editions.drop_while { |e| e.state != "published" } }
    end
  end
end
