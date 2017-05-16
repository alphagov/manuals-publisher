require "services"
require "adapters"
require "gds_api_constants"

class ManualRelocator
  attr_reader :from_slug, :to_slug

  def initialize(from_slug, to_slug)
    @from_slug = from_slug
    @to_slug = to_slug
  end

  def self.move(from_slug, to_slug)
    new(from_slug, to_slug).move!
  end

  def move!
    validate_manuals
    redirect_and_remove
    reslug
    redraft_and_republish
  end

  def old_manual_record
    @old_manual_record ||= fetch_manual(to_slug)
  end

  def new_manual_record
    @new_manual_record ||= fetch_manual(from_slug)
  end

  def new_manual
    Manual.build_manual_for(new_manual_record, load_associations: false)
  end

private

  def fetch_manual(slug)
    manuals = ManualRecord.where(slug: slug)
    raise "No manual found for slug '#{slug}'" if manuals.count == 0
    raise "More than one manual found for slug '#{slug}'" if manuals.count > 1
    manuals.first
  end

  def old_section_uuids
    @old_section_uuids ||= old_manual_record.editions.flat_map(&:section_uuids).uniq
  end

  def new_section_uuids
    @new_section_uuids ||= new_manual_record.editions.flat_map(&:section_uuids).uniq
  end

  def validate_manuals
    raise "Manual to remove (#{to_slug}) should be published" unless manual_is_currently_published?(old_manual_record)
    raise "Manual to reslug (#{from_slug}) should be published" unless manual_is_currently_published?(new_manual_record)
  end

  def manual_is_currently_published?(manual)
    # to be currently published either...
    # 1. the latest edition is published
    (manual.latest_edition.state == "published") ||
    # or
    # 2. the last two editions are published and draft
      (manual.editions.order_by([:version_number, :desc]).limit(2).map(&:state) == %w(draft published))
  end

  def redirect_and_remove
    if old_manual_record.editions.any?
      # Redirect all sections of the manual we're going to remove
      # to prevent dead bookmarked URLs.
      old_section_uuids.each do |section_uuid|
        editions = all_editions_of_section(section_uuid)
        section_slug = editions.first.slug

        begin
          if old_sections_reused_in_new_manual_record.include? section_uuid
            puts "Issuing gone for content item '/#{section_slug}' as it will be reused by a section in '#{new_manual_record.slug}'"
            send_gone(section_uuid, section_slug)
          else
            puts "Redirecting content item '/#{section_slug}' to '/#{old_manual_record.slug}'"
            publishing_api.unpublish(section_uuid,
                                     type: "redirect",
                                     alternative_path: "/#{old_manual_record.slug}",
                                     discard_drafts: true)
          end
        rescue GdsApi::HTTPNotFound
          puts "Content item with section_uuid #{section_uuid} not present in the publishing API"
        end

        # Destroy all the editons of this manual as it's going away
        editions.map(&:destroy)
      end
    end

    puts "Destroying old PublicationLogs for #{old_manual_record.slug}"
    PublicationLog.change_notes_for(old_manual_record.slug).each(&:destroy)

    # Destroy the manual record
    puts "Destroying manual #{old_manual_record.manual_id}"
    old_manual_record.destroy

    puts "Issuing gone for #{old_manual_record.manual_id}"
    send_gone(old_manual_record.manual_id, old_manual_record.slug)
  end

  def old_sections_reused_in_new_manual_record
    @old_sections_reused_in_new_manual_record ||= _calculate_old_sections_reused_in_new_manual_record
  end

  def _calculate_old_sections_reused_in_new_manual_record
    old_section_uuids_and_section_slugs = old_section_uuids.map do |section_uuid|
      [section_uuid, most_recent_edition_of_section(section_uuid).slug.gsub(to_slug, "")]
    end

    new_section_slugs = new_section_uuids.map do |section_uuid|
      most_recent_edition_of_section(section_uuid).slug.gsub(from_slug, "")
    end

    old_section_uuids_and_section_slugs.
      select { |_section_uuid, slug| new_section_slugs.include? slug }.
      map { |section_uuid, _slug| section_uuid }
  end

  def most_recent_published_edition_of_section(section_uuid)
    all_editions_of_section(section_uuid).select { |edition| edition.state == "published" }.first
  end

  def most_recent_edition_of_section(section_uuid)
    all_editions_of_section(section_uuid).first
  end

  def all_editions_of_section(section_uuid)
    SectionEdition.all_for_section(section_uuid).order_by([:version_number, :desc])
  end

  def reslug
    # Reslug the manual sections
    new_section_uuids.each do |section_uuid|
      sections = all_editions_of_section(section_uuid)
      sections.each do |section|
        new_section_slug = section.slug.gsub(from_slug, to_slug)
        puts "Reslugging section '#{section.slug}' as '#{new_section_slug}'"
        section.set(:slug, new_section_slug)
      end
    end

    # Reslug the manual
    puts "Reslugging manual '#{new_manual_record.slug}' as '#{to_slug}'"
    new_manual_record.set(:slug, to_slug)

    # Reslug the existing publication logs
    puts "Reslugging publication logs for #{from_slug} to #{to_slug}"
    PublicationLog.change_notes_for(from_slug).each do |publication_log|
      publication_log.set(:slug, publication_log.slug.gsub(from_slug, to_slug))
    end

    # Clean up manual sections belonging to the temporary manual path
    new_section_uuids.each do |section_uuid|
      puts "Redirecting #{section_uuid} to '/#{to_slug}'"
      most_recent_edition = most_recent_edition_of_section(section_uuid)
      publishing_api.unpublish(section_uuid,
                               type: "redirect",
                               alternative_path: "/#{most_recent_edition.slug}",
                               discard_drafts: true)
    end

    # Clean up the drafted manual in the Publishing API
    puts "Redirecting #{new_manual_record.manual_id} to '/#{to_slug}'"
    publishing_api.unpublish(new_manual_record.manual_id,
                             type: "redirect",
                             alternative_path: "/#{to_slug}",
                             discard_drafts: true)
  end

  def redraft_and_republish
    manual_versions = new_manual.current_versions

    if manual_versions[:published].present?
      manual_to_publish = manual_versions[:published]
      send_draft(manual_to_publish)

      puts "Publishing published edition of manual: #{manual_to_publish.id}"
      publishing_api.publish(manual_to_publish.id, GdsApiConstants::PublishingApiV2::REPUBLISH_UPDATE_TYPE)
      manual_to_publish.sections.each do |section|
        puts "Publishing published edition of manual section: #{section.uuid}"
        publishing_api.publish(section.uuid, GdsApiConstants::PublishingApiV2::REPUBLISH_UPDATE_TYPE)
      end
    end

    send_draft(manual_versions[:draft]) if manual_versions[:draft].present?
  end

  def send_draft(manual)
    puts "Sending a draft of manual #{manual.id} (version: #{manual.version_number})"
    manual.sections.each do |section|
      puts "Sending a draft of manual section #{section.uuid} (version: #{section.version_number})"
    end
    Adapters.publishing.save(manual, include_links: false)
  end

  def send_gone(section_uuid, slug)
    # We should be able to use
    #   publishing_api.unpublish(section_uuid, type: 'gone')
    # here, but that doesn't leave the base_path in a state where
    # publishing_api will let us re-use it.  Sending a draft gone object
    # and then publishing it does though.  Might want to check if we can
    # go back to the unpublish version at some point though.
    gone_item = {
      base_path: "/#{slug}",
      content_id: section_uuid,
      document_type: "gone",
      publishing_app: GdsApiConstants::PublishingApiV2::PUBLISHING_APP,
      schema_name: "gone",
      routes: [
        {
          path: "/#{slug}",
          type: GdsApiConstants::PublishingApiV2::EXACT_ROUTE_TYPE
        }
      ]
    }
    publishing_api.put_content(section_uuid, gone_item)
    publishing_api.publish(section_uuid, GdsApiConstants::PublishingApiV2::MAJOR_UPDATE_TYPE)
  end

  def publishing_api
    Services.publishing_api
  end
end
