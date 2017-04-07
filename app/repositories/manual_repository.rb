require 'manual'

class ManualRepository
  def initialize(collection)
    @collection = collection
  end

  def [](manual_id)
    manual_record = collection.find_by(manual_id: manual_id)
    return nil unless manual_record

    build_manual_for(manual_record)
  end

  def all(load_associations: true)
    collection.all_by_updated_at.lazy.map { |manual_record|
      build_manual_for(manual_record, load_associations: load_associations)
    }
  end

  def slug_unique?(manual)
    collection.where(
      :slug => manual.slug,
      :manual_id.ne => manual.id,
    ).empty?
  end

private

  attr_reader :collection

  def build_manual_for(manual_record, load_associations: true)
    edition = manual_record.latest_edition

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

    if load_associations
      manual_with_sections = add_sections_to_manual(base_manual, edition)
      add_publish_tasks_to_manual(manual_with_sections)
    else
      base_manual
    end
  end

  def add_sections_to_manual(manual, edition)
    section_repository = SectionRepository.new(manual: manual)

    sections = Array(edition.section_ids).map { |section_id|
      section_repository.fetch(section_id)
    }

    removed_sections = Array(edition.removed_section_ids).map { |section_id|
      begin
        section_repository.fetch(section_id)
      rescue KeyError
        raise RemovedSectionIdNotFoundError, "No section found for ID #{section_id}"
      end
    }

    manual.sections = sections
    manual.removed_sections = removed_sections
    manual
  end

  def add_publish_tasks_to_manual(manual)
    tasks = ManualPublishTask.for_manual(manual)
    ManualWithPublishTasks.new(manual, publish_tasks: tasks)
  end

  class RemovedSectionIdNotFoundError < StandardError; end
end
