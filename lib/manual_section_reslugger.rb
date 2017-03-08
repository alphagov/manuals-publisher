require "gds_api/content_store"
require "manual_service_registry"

class ManualSectionReslugger
  RUMMAGER_FORMAT = "manual_section".freeze
  class Error < RuntimeError; end

  def initialize(manual_slug, current_section_slug, new_section_slug)
    @manual_slug = manual_slug
    @current_section_slug = current_section_slug
    @new_section_slug = new_section_slug
  end

  def call
    validate

    update_slug
    publish_manual
    redirect_section
    remove_old_section_from_rummager
  end

private

  def validate
    validate_manual
    validate_current_section
    validate_new_section
  end

  def validate_manual
    raise Error.new("Manual not found for manual_slug `#{manual_slug}`") if manual_record.nil?
  end

  def validate_current_section
    validate_current_section_in_database
    validate_current_section_in_content_store
  end

  def validate_current_section_in_database
    raise Error.new("Manual Section does not exist in database") if current_section_edition.nil?
  end

  def validate_current_section_in_content_store
    raise Error.new("Manual Section does not exist in content store") if current_section_in_content_store.nil?
    raise Error.new("Manual Section already withdrawn") if current_section_in_content_store.format == "gone"
  end

  def validate_new_section
    validate_new_section_in_database
    validate_new_section_in_content_store
  end

  def validate_new_section_in_database
    section = section_in_database(full_new_section_slug)
    raise Error.new("Manual Section already exists in database") if section
  end

  def validate_new_section_in_content_store
    section = section_in_content_store(full_new_section_slug)
    raise Error.new("Manual Section already exists in content store") if section
  end

  def redirect_section
    raise 'GdsApi::PublishingApi#put_content_item was removed in gds-api-adapters v38.0.0'
  end

  def update_slug
    new_edition_for_slug_change.update_attribute(:slug, full_new_section_slug)
  end

  def new_edition_for_slug_change
    _manual, document = ManualDocumentServiceRegistry.new.update(context_for_section_edition_update).call
    document.latest_edition
  end

  FakeController = Struct.new(:params)

  def context_for_section_edition_update
    params_hash = {
      "id" => current_section_edition.document_id,
      "document" => {
        title: current_section_edition.title,
        summary: current_section_edition.summary,
        body: current_section_edition.body,
        minor_update: false,
        change_note: change_note
      },
      "manual_id" => manual_record.manual_id
    }
    FakeController.new(params_hash)
  end

  def change_note
    "Updated section slug from #{@current_section_slug} to #{@new_section_slug}"
  end

  def publish_manual
    ManualServiceRegistry.new.publish(manual_record.manual_id, manual_version_number).call
  end

  def manual_record
    @manual_record ||= ManualRecord.where(slug: @manual_slug).last
  end

  def manual_version_number
    manual_repository.fetch(manual_record.manual_id).version_number
  end

  def manual_repository
    RepositoryRegistry.create.manual_repository
  end

  def current_section_edition
    @current_section_edition ||= section_in_database(full_current_section_slug)
  end

  def current_section_in_content_store
    @current_section_in_cs ||= section_in_content_store(full_current_section_slug)
  end

  def section_in_database(slug)
    SpecialistDocumentEdition.where(slug: slug).last
  end

  def section_in_content_store(slug)
    content_store.content_item("/#{slug}")
  end

  def content_store
    GdsApi::ContentStore.new(Plek.current.find("content-store"))
  end

  def full_current_section_slug
    full_section_slug(@current_section_slug)
  end

  def full_new_section_slug
    full_section_slug(@new_section_slug)
  end

  def full_section_slug(slug)
    "#{manual_record.slug}/#{slug}"
  end

  def remove_old_section_from_rummager
    rummager = RummagerApi.instance
    rummager.delete_document(RUMMAGER_FORMAT, "/#{full_current_section_slug}")
  end
end
