require "gds_api/content_store"

class ManualReslugger
  class Error < RuntimeError; end

  def initialize(old_slug, new_slug)
    @old_slug = old_slug
    @new_slug = new_slug
  end

  def call
    validate

    reslug_sections
    reslug_publication_logs
    manual_record.set(slug: new_slug)

    Manual::RepublishService.call(user:, manual_id: manual_record.manual_id)
  end

private

  attr_reader :old_slug, :new_slug

  def validate
    raise Error, "Old and new slugs are the same" if old_slug == new_slug
    raise Error, "Manual not found: #{old_slug}" if manual_record.nil?
    raise Error, "A manual already exists with slug: #{new_slug}" if ManualRecord.where(slug: new_slug).exists?
    raise Error, "Something already exists in the content store at: /#{new_slug}" if in_content_store?(new_slug)
  end

  def reslug_sections
    SectionEdition.all_for_sections(*section_uuids).each do |section_edition|
      section_edition.set(slug: replace_slug_prefix(section_edition.slug))
    end
  end

  def reslug_publication_logs
    PublicationLog.with_slug_prefix(old_slug).each do |publication_log|
      publication_log.set(slug: replace_slug_prefix(publication_log.slug))
    end
  end

  def section_uuids
    manual_record.editions.flat_map { |edition| edition.section_uuids.to_a + edition.removed_section_uuids.to_a }.uniq
  end

  # Only replace the old slug when it is the whole start of the path, so that
  # "guidance/my-manual" doesn't match "guidance/my-manual-2/section".
  def replace_slug_prefix(slug)
    slug.sub(%r{\A#{Regexp.escape(old_slug)}(?=/|\z)}, new_slug)
  end

  def manual_record
    @manual_record ||= begin
      records = ManualRecord.where(slug: old_slug).to_a
      raise Error, "Multiple manuals found for slug: #{old_slug}" if records.size > 1

      records.first
    end
  end

  def in_content_store?(slug)
    Services.content_store.content_item("/#{slug}")
    true
  rescue GdsApi::ContentStore::ItemNotFound
    false
  end

  def user
    User.gds_editor
  end
end
