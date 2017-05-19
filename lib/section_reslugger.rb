require "gds_api/content_store"
require "services"
require "adapters"

class SectionReslugger
  class Error < RuntimeError; end

  def initialize(manual_slug, old_section_slug, new_section_slug)
    @manual_slug = manual_slug
    @old_section_slug = old_section_slug
    @new_section_slug = new_section_slug
  end

  def call
    validate

    old_section = Section.find(manual, old_section_edition.section_uuid)

    update_slug
    publish_manual
    redirect_section(old_section)
    remove_from_search_index(old_section)
  end

private

  def validate
    validate_old_section
    validate_new_section
  end

  def validate_old_section
    validate_old_section_in_database
    validate_old_section_in_content_store
  end

  def validate_old_section_in_database
    raise Error.new("Manual Section does not exist in database") if old_section_edition.nil?
  end

  def validate_old_section_in_content_store
    raise Error.new("Manual Section does not exist in content store") if old_section_in_content_store.nil?
    raise Error.new("Manual Section already withdrawn") if old_section_in_content_store['format'] == "gone"
  end

  def validate_new_section
    validate_new_section_in_database
    validate_new_section_in_content_store
  end

  def validate_new_section_in_database
    section_edition = section_edition_in_database(full_new_section_slug)
    raise Error.new("Manual Section already exists in database") if section_edition
  end

  def validate_new_section_in_content_store
    section = section_in_content_store(full_new_section_slug)
    raise Error.new("Manual Section already exists in content store") if section
  rescue GdsApi::ContentStore::ItemNotFound # rubocop:disable Lint/HandleExceptions
  end

  def redirect_section(section)
    Adapters.publishing.redirect_section(section, to: "/#{full_new_section_slug}")
  end

  def update_slug
    new_edition_for_slug_change.update_attribute(:slug, full_new_section_slug)
  end

  def new_edition_for_slug_change
    user = User.gds_editor

    service = Section::UpdateService.new(
      user: user,
      manual_id: manual.id,
      section_uuid: old_section_edition.section_uuid,
      attributes: {
        title: old_section_edition.title,
        summary: old_section_edition.summary,
        body: old_section_edition.body,
        minor_update: false,
        change_note: change_note
      }
    )
    _manual, section = service.call
    section.latest_edition
  end

  def change_note
    "Updated section slug from #{@old_section_slug} to #{@new_section_slug}"
  end

  def publish_manual
    service = Manual::PublishService.new(
      user: user,
      manual_id: manual.id,
      version_number: manual_version_number
    )
    service.call
  end

  def user
    User.gds_editor
  end

  def manual
    Manual.find_by_slug!(@manual_slug, user)
  rescue Manual::NotFoundError, Manual::AmbiguousSlugError => e
    raise Error.new(e.message)
  end

  def manual_version_number
    manual.version_number
  end

  def old_section_edition
    @old_section_edition ||= section_edition_in_database(full_old_section_slug)
  end

  def old_section_in_content_store
    @old_section_in_cs ||= section_in_content_store(full_old_section_slug)
  end

  def section_edition_in_database(slug)
    SectionEdition.where(slug: slug).last
  end

  def section_in_content_store(slug)
    content_store.content_item("/#{slug}")
  end

  def content_store
    Services.content_store
  end

  def full_old_section_slug
    full_section_slug(@old_section_slug)
  end

  def full_new_section_slug
    full_section_slug(@new_section_slug)
  end

  def full_section_slug(slug)
    "#{manual.slug}/#{slug}"
  end

  def remove_from_search_index(section)
    Adapters.search_index.remove_section(section)
  end
end
