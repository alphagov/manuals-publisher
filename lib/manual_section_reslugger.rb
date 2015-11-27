require "gds_api/content_store"
require "manual_service_registry"

class ManualSectionReslugger
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
  end

  private

  def validate
    validate_manual
    validate_current_section
    validate_new_section
  end

  def validate_manual
    raise Error.new("Manual not found for manual_slug `#{manual_slug}`") if manual.nil?
  end

  def validate_current_section
    validate_current_section_in_database
    validate_current_section_in_content_store
  end

  def validate_current_section_in_database
    raise Error.new("Manual Section does not exist in database") if current_section.nil?
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
    PublishingAPIRedirecter.new(
      publishing_api: SpecialistPublisherWiring.get(:publishing_api),
      entity: current_section,
      redirect_to_location: "/#{full_new_section_slug}"
    ).call
  end

  def update_slug
    current_section.update_attribute(:slug, full_new_section_slug)
    #Manual only republishes documents that have exported_at set to nil
    current_section.update_attribute(:exported_at, nil)
  end

  def publish_manual
    ManualServiceRegistry.new.queue_publish(manual.manual_id).call
  end

  def manual
    @manual ||= ManualRecord.where(slug: @manual_slug).last
  end

  def current_section
    @current_section ||= section_in_database(full_current_section_slug)
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
    "#{manual.slug}/#{slug}"
  end
end
