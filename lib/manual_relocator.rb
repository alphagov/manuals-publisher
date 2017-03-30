require "services"

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

  def old_manual
    @old_manual ||= fetch_manual(to_slug)
  end

  def new_manual
    @new_manual ||= fetch_manual(from_slug)
  end

private

  def fetch_manual(slug)
    manuals = ManualRecord.where(slug: slug)
    raise "No manual found for slug '#{slug}'" if manuals.count == 0
    raise "More than one manual found for slug '#{slug}'" if manuals.count > 1
    manuals.first
  end

  def old_section_ids
    @old_section_ids ||= old_manual.editions.flat_map(&:section_ids).uniq
  end

  def new_section_ids
    @new_section_ids ||= new_manual.editions.flat_map(&:section_ids).uniq
  end

  def validate_manuals
    raise "Manual to remove (#{to_slug}) should be published" unless manual_is_currently_published?(old_manual)
    raise "Manual to reslug (#{from_slug}) should be published" unless manual_is_currently_published?(new_manual)
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
    if old_manual.editions.any?
      # Redirect all sections of the manual we're going to remove
      # to prevent dead bookmarked URLs.
      old_section_ids.each do |section_id|
        editions = all_editions_of_section(section_id)
        section_slug = editions.first.slug

        begin
          if old_sections_reused_in_new_manual.include? section_id
            puts "Issuing gone for content item '/#{section_slug}' as it will be reused by a section in '#{new_manual.slug}'"
            send_gone(section_id, section_slug)
          else
            puts "Redirecting content item '/#{section_slug}' to '/#{old_manual.slug}'"
            publishing_api.unpublish(section_id,
                                     type: "redirect",
                                     alternative_path: "/#{old_manual.slug}",
                                     discard_drafts: true)
          end
        rescue GdsApi::HTTPNotFound
          puts "Content item with content_id #{section_id} not present in the publishing API"
        end

        # Destroy all the editons of this manual as it's going away
        editions.map(&:destroy)
      end
    end

    puts "Destroying old PublicationLogs for #{old_manual.slug}"
    PublicationLog.change_notes_for(old_manual.slug).each(&:destroy)

    # Destroy the manual record
    puts "Destroying manual #{old_manual.manual_id}"
    old_manual.destroy

    puts "Issuing gone for #{old_manual.manual_id}"
    send_gone(old_manual.manual_id, old_manual.slug)
  end

  def old_sections_reused_in_new_manual
    @old_sections_reused_in_new_manual ||= _calculate_old_sections_reused_in_new_manual
  end

  def _calculate_old_sections_reused_in_new_manual
    old_section_ids_and_section_slugs = old_section_ids.map do |section_id|
      [section_id, most_recent_edition_of_section(section_id).slug.gsub(to_slug, "")]
    end

    new_section_slugs = new_section_ids.map do |section_id|
      most_recent_edition_of_section(section_id).slug.gsub(from_slug, "")
    end

    old_section_ids_and_section_slugs.
      select { |_section_id, slug| new_section_slugs.include? slug }.
      map { |section_id, _slug| section_id }
  end

  def most_recent_published_edition_of_section(section_id)
    all_editions_of_section(section_id).select { |edition| edition.state == "published" }.first
  end

  def most_recent_edition_of_section(section_id)
    all_editions_of_section(section_id).first
  end

  def all_editions_of_section(section_id)
    SectionEdition.where(section_id: section_id).order_by([:version_number, :desc])
  end

  def reslug
    # Reslug the manual sections
    new_section_ids.each do |section_id|
      sections = all_editions_of_section(section_id)
      sections.each do |section|
        reslug_msg = "Reslugging section '#{section.slug}'"
        new_section_slug = section.slug.gsub(from_slug, to_slug)
        puts "#{reslug_msg} as '#{section.slug}'"
        section.set(:slug, new_section_slug)
      end
    end

    # Reslug the manual
    puts "Reslugging manual '#{new_manual.slug}' as '#{to_slug}'"
    new_manual.set(:slug, to_slug)

    # Reslug the existing publication logs
    puts "Reslugging publication logs for #{from_slug} to #{to_slug}"
    PublicationLog.change_notes_for(from_slug).each do |publication_log|
      publication_log.set(:slug, publication_log.slug.gsub(from_slug, to_slug))
    end

    # Clean up manual sections belonging to the temporary manual path
    new_section_ids.each do |section_id|
      puts "Redirecting #{section_id} to '/#{to_slug}'"
      most_recent_edition = most_recent_edition_of_section(section_id)
      publishing_api.unpublish(section_id,
                               type: "redirect",
                               alternative_path: "/#{most_recent_edition.slug}",
                               discard_drafts: true)
    end

    # Clean up the drafted manual in the Publishing API
    puts "Redirecting #{new_manual.manual_id} to '/#{to_slug}'"
    publishing_api.unpublish(new_manual.manual_id,
                             type: "redirect",
                             alternative_path: "/#{to_slug}",
                             discard_drafts: true)
  end

  def redraft_and_republish
    manual_versions = VersionedManualRepository.get_manual(new_manual.manual_id)

    if manual_versions[:published].present?
      manual_to_publish = manual_versions[:published]
      send_draft(manual_to_publish)

      puts "Publishing published edition of manual: #{manual_to_publish.id}"
      publishing_api.publish(manual_to_publish.id, "republish")
      manual_to_publish.sections.each do |section|
        puts "Publishing published edition of manual section: #{section.id}"
        publishing_api.publish(section.id, "republish")
      end
    end

    send_draft(manual_versions[:draft]) if manual_versions[:draft].present?
  end

  def send_draft(manual)
    organisation = fetch_organisation(manual.organisation_slug)

    puts "Sending a draft of manual #{manual.id} (version: #{manual.version_number})"
    ManualPublishingAPIExporter.new(
      organisation, manual
    ).call

    manual.sections.each do |section|
      puts "Sending a draft of manual section #{section.id} (version: #{section.version_number})"
      SectionPublishingAPIExporter.new(
        organisation, manual, section
      ).call
    end
  end

  def send_gone(section_id, slug)
    # We should be able to use
    #   publishing_api.unpublish(section_id, type: 'gone')
    # here, but that doesn't leave the base_path in a state where
    # publishing_api will let us re-use it.  Sending a draft gone object
    # and then publishing it does though.  Might want to check if we can
    # go back to the unpublish version at some point though.
    gone_item = {
      base_path: "/#{slug}",
      content_id: section_id,
      document_type: "gone",
      publishing_app: "manuals-publisher",
      schema_name: "gone",
      routes: [
        {
          path: "/#{slug}",
          type: "exact"
        }
      ]
    }
    publishing_api.put_content(section_id, gone_item)
    publishing_api.publish(section_id, "major")
  end

  def publishing_api
    Services.publishing_api_v2
  end

  def fetch_organisation(slug)
    OrganisationFetcher.fetch(slug)
  end
end
