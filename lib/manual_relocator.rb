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

  def old_manual_document_ids
    @old_manual_document_ids ||= old_manual.editions.flat_map(&:document_ids).uniq
  end

  def new_manual_document_ids
    @new_manual_document_ids ||= new_manual.editions.flat_map(&:document_ids).uniq
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
      old_manual_document_ids.each do |document_id|
        editions = all_editions_of_section(document_id)
        section_slug = editions.first.slug

        begin
          if old_sections_reused_in_new_manual.include? document_id
            puts "Issuing gone for content item '/#{section_slug}' as it will be reused by a section in '#{new_manual.slug}'"
            send_gone(document_id, section_slug)
          else
            puts "Redirecting content item '/#{section_slug}' to '/#{old_manual.slug}'"
            publishing_api.unpublish(document_id,
                                     type: "redirect",
                                     alternative_path: "/#{old_manual.slug}",
                                     discard_drafts: true)
          end
        rescue GdsApi::HTTPNotFound
          puts "Content item with content_id #{document_id} not present in the publishing API"
        end

        # Destroy all the editons of this manual as it's going away
        editions.map(&:destroy)
      end
    end

    puts "Destroying old PublicationLogs for #{old_manual.slug}"
    PublicationLog.change_notes_for(old_manual.slug).each { |log| log.destroy }

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
    old_document_ids_and_section_slugs = old_manual_document_ids.map do |document_id|
      [document_id, most_recent_edition_of_section(document_id).slug.gsub(to_slug, "")]
    end

    new_section_slugs = new_manual_document_ids.map do |document_id|
      most_recent_edition_of_section(document_id).slug.gsub(from_slug, "")
    end

    old_document_ids_and_section_slugs.
      select { |_document_id, slug| new_section_slugs.include? slug }.
      map { |document_id, _slug| document_id }
  end

  def most_recent_published_edition_of_section(document_id)
    all_editions_of_section(document_id).select { |edition| edition.state == "published" }.first
  end

  def most_recent_edition_of_section(document_id)
    all_editions_of_section(document_id).first
  end

  def all_editions_of_section(document_id)
    SpecialistDocumentEdition.where(document_id: document_id).order_by([:version_number, :desc])
  end

  def reslug
    # Reslug the manual sections
    new_manual_document_ids.each do |document_id|
      sections = all_editions_of_section(document_id)
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
    new_manual_document_ids.each do |document_id|
      puts "Redirecting #{document_id} to '/#{to_slug}'"
      most_recent_edition = most_recent_edition_of_section(document_id)
      publishing_api.unpublish(document_id,
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
    if new_manual.latest_edition.state == "draft"
      published_edition = new_manual.editions.order_by([:version_number, :desc]).limit(2).last

      send_draft(
        new_manual,
        published_edition,
        published_edition.document_ids.map { |document_id| most_recent_published_edition_of_section(document_id) }
      )

      puts "Publishing previously published edition of manual: #{new_manual.manual_id}"
      publishing_api.publish(new_manual.manual_id, "republish")
      published_edition.document_ids.each do |document_id|
        puts "Publishing previously published edition of manual section: #{document_id}"
        publishing_api.publish(document_id, "republish")
      end
    end

    send_draft(
      new_manual,
      new_manual.latest_edition,
      new_manual.latest_edition.document_ids.map { |document_id| most_recent_edition_of_section(document_id) }
    )

    if new_manual.latest_edition.state == "published"
      puts "Publishing latest edition of manual: #{new_manual.manual_id}"
      publishing_api.publish(new_manual.manual_id, "republish")
      new_manual.latest_edition.document_ids.each do |document_id|
        puts "Publishing latest edition of manual section: #{document_id}"
        publishing_api.publish(document_id, "republish")
      end
    end
  end

  def send_draft(manual, manual_edition, document_editions)
    put_content = publishing_api.method(:put_content)
    organisation = fetch_organisation(new_manual.organisation_slug)
    manual_renderer = ManualsPublisherWiring.get(:manual_renderer)
    manual_document_renderer = ManualsPublisherWiring.get(:manual_document_renderer)

    simple_manual = build_simple_manual(
      manual,
      manual_edition,
      document_editions.map do |document_edition|
        build_simple_section(document_edition)
      end
    )

    puts "Sending a draft of manual #{simple_manual.id} (version: #{simple_manual.version_number})"
    ManualPublishingAPIExporter.new(
      put_content, organisation, manual_renderer, PublicationLog, simple_manual
    ).call

    simple_manual.documents.each do |simple_document|
      puts "Sending a draft of manual section #{simple_document.id} (version: #{simple_document.version_number})"
      ManualSectionPublishingAPIExporter.new(
        put_content, organisation, manual_document_renderer, simple_manual, simple_document
      ).call
    end
  end

  def send_gone(document_id, slug)
    # We should be able to use
    #   publishing_api.unpublish(document_id, type: 'gone')
    # here, but that doesn't leave the base_path in a state where
    # publishing_api will let us re-use it.  Sending a draft gone object
    # and then publishing it does though.  Might want to check if we can
    # go back to the unpublish version at some point though.
    gone_item = {
      base_path: "/#{slug}",
      content_id: document_id,
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
    publishing_api.put_content(document_id, gone_item)
    publishing_api.publish(document_id, "major")
  end

  def publishing_api
    ManualsPublisherWiring.get(:publishing_api_v2)
  end

  def fetch_organisation(slug)
    ManualsPublisherWiring.get(:organisation_fetcher).call(slug)
  end

  def build_simple_manual(manual_record, manual_edition, documents)
    SimpleManual.new(
      id: manual_record.manual_id,
      slug: manual_record.slug,
      title: manual_edition.title,
      summary: manual_edition.summary,
      body: manual_edition.body,
      organisation_slug: manual_record.organisation_slug,
      state: manual_edition.state,
      version_number: manual_edition.version_number,
      updated_at: manual_edition.updated_at,
      documents: documents,
    )
  end

  class SimpleManual
    attr_reader :id, :slug, :title, :summary, :body, :organisation_slug,
        :state, :version_number, :updated_at, :documents

    def initialize(id:, slug:, title:, summary:, body:, organisation_slug:, state:, version_number:, updated_at:, documents:)
      @id = id
      @slug = slug
      @title = title
      @summary = summary
      @body = body
      @organisation_slug = organisation_slug
      @state = state
      @version_number = version_number
      @updated_at = updated_at
      @documents = documents
    end

    def attributes
      {
        id: id, slug: slug, title: title, summary: summary, body: body,
        organisation_slug: organisation_slug, state: state,
        version_number: version_number, updated_at: updated_at,
      }
    end
  end

  def build_simple_section(section_edition)
    SimpleSection.new(
      id: section_edition.document_id,
      title: section_edition.title,
      slug: section_edition.slug,
      summary: section_edition.summary,
      body: section_edition.body,
      document_type: section_edition.document_type,
      updated_at: section_edition.updated_at,
      version_number: section_edition.version_number,
      extra_fields: section_edition.extra_fields,
      public_updated_at: section_edition.public_updated_at,
      minor_update: section_edition.minor_update,
      attachments: section_edition.attachments.to_a,
      needs_exporting: section_edition.exported_at.nil?,
    )
  end

  class SimpleSection
    attr_reader :id, :title, :slug, :summary, :body, :document_type, :updated_at,
      :version_number, :extra_fields, :public_updated_at, :minor_update,
      :attachments, :needs_exporting

    def initialize(id:, title:, slug:, summary:, body:, document_type:, updated_at:, version_number:, extra_fields:, public_updated_at:, minor_update:, attachments:, needs_exporting:)
      @id = id
      @title = title
      @slug = slug
      @summary = summary
      @body = body
      @document_type = document_type
      @updated_at = updated_at
      @version_number = version_number
      @extra_fields = extra_fields
      @public_updated_at = public_updated_at
      @minor_update = minor_update
      @attachments = attachments
      @needs_exporting = needs_exporting
    end

    def attributes
      {
        id: id, title: title, slug: slug, summary: summary, body: body,
        document_type: document_type, updated_at: updated_at,
        version_number: version_number, extra_fields: extra_fields,
        public_updated_at: public_updated_at, minor_update: minor_update
      }
    end

    def minor_update?
      !!minor_update
    end

    def needs_exporting?
      !!needs_exporting
    end
  end
end
