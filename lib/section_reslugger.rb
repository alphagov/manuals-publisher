require "gds_api/content_store"
require "services"

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
    redirect_section
    remove_from_search_index(old_section)
  end

private

  def validate
    validate_manual
    validate_old_section
    validate_new_section
  end

  def validate_manual
    raise Error.new("Manual not found for manual_slug `#{@manual_slug}`") if manual_record.nil?
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

  def redirect_section
    PublishingAPIRedirecter.new(
      publishing_api: Services.publishing_api,
      entity: old_section_edition,
      redirect_to_location: "/#{full_new_section_slug}"
    ).call
  end

  def update_slug
    new_edition_for_slug_change.update_attribute(:slug, full_new_section_slug)
  end

  def new_edition_for_slug_change
    manual_records = ManualRecord.all
    user = OpenStruct.new(manual_records: manual_records)

    service = Section::UpdateService.new(
      context: context_for_section_edition_update(user),
    )
    _manual, section = service.call
    section.latest_edition
  end

  FakeController = Struct.new(:params, :current_user)

  def context_for_section_edition_update(user)
    params_hash = {
      "id" => old_section_edition.section_uuid,
      "section" => {
        title: old_section_edition.title,
        summary: old_section_edition.summary,
        body: old_section_edition.body,
        minor_update: false,
        change_note: change_note
      },
      "manual_id" => manual_record.manual_id,
    }
    FakeController.new(params_hash, user)
  end

  def change_note
    "Updated section slug from #{@old_section_slug} to #{@new_section_slug}"
  end

  def publish_manual
    service = Manual::PublishService.new(
      manual_id: manual_record.manual_id,
      version_number: manual_version_number,
      context: context,
    )
    service.call
  end

  def context
    OpenStruct.new(current_user: User.gds_editor)
  end

  def manual_record
    @manual_record ||= ManualRecord.where(slug: @manual_slug).last
  end

  def manual
    Manual.find(manual_record.manual_id, context.current_user)
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
    "#{manual_record.slug}/#{slug}"
  end

  def remove_from_search_index(section)
    SearchIndexAdapter.new.remove_section(section)
  end
end
