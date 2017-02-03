require "manual_publishing_api_exporter"
require "manual_section_publishing_api_exporter"
require "publishing_api_withdrawer"
require "rummager_indexer"
require "formatters/manual_indexable_formatter"
require "formatters/manual_section_indexable_formatter"

class ManualObserversRegistry
  def publication
    # The order here is important. For example content exporting
    # should happen before publishing to search.
    #
    # A draft export step follows publication logging as this ensures that
    # change notes that relate to the current draft are pushed straight to the
    # publishing API rather than on the subsequent draft-publish cycle.
    [
      publication_logger,
      publishing_api_draft_exporter,
      publishing_api_publisher,
      rummager_exporter,
    ]
  end

  def republication
    [
      publishing_api_draft_exporter,
      publishing_api_publisher,
      rummager_exporter,
    ]
  end

  def update
    [
      publishing_api_draft_exporter
    ]
  end
  alias_method :update_original_publication_date, :update

  def creation
    [
      publishing_api_draft_exporter
    ]
  end

  def withdrawal
    [
      publishing_api_withdrawer,
      rummager_withdrawer,
    ]
  end

private
  def publication_logger
    ->(manual, _: nil) {
      manual.documents.each do |doc|
        next unless doc.needs_exporting?
        next if doc.minor_update?

        PublicationLog.create!(
          title: doc.title,
          slug: doc.slug,
          version_number: doc.version_number,
          change_note: doc.change_note,
        )
      end

      manual.removed_documents.each do |doc|
        next if doc.withdrawn?
        next if doc.minor_update?

        PublicationLog.create!(
          title: doc.title,
          slug: doc.slug,
          version_number: doc.version_number,
          change_note: doc.change_note,
        )
      end
    }
  end

  def rummager_exporter
    ->(manual, _ = nil) {
      indexer = RummagerIndexer.new

      indexer.add(
        ManualIndexableFormatter.new(manual)
      )

      manual.documents.each do |section|
        indexer.add(
          ManualSectionIndexableFormatter.new(
            MarkdownAttachmentProcessor.new(section),
            manual,
          )
        )
      end

      manual.removed_documents.each do |section|
        indexer.delete(
          ManualSectionIndexableFormatter.new(section, manual),
        )
      end
    }
  end

  def rummager_withdrawer
    ->(manual, _ = nil) {
      indexer = RummagerIndexer.new

      indexer.delete(
        ManualIndexableFormatter.new(manual)
      )

      manual.documents.each do |section|
        indexer.delete(
          ManualSectionIndexableFormatter.new(
            MarkdownAttachmentProcessor.new(section),
            manual,
          )
        )
      end
    }
  end

  def publishing_api_publisher
    ->(manual, action = nil) {
      PublishingAPIPublisher.new(
        publishing_api: publishing_api_v2,
        entity: manual,
      ).call

      manual.documents.each do |document|
        next if !document.needs_exporting? && action != :republish

        PublishingAPIPublisher.new(
          publishing_api: publishing_api_v2,
          entity: document,
        ).call

        document.mark_as_exported! if action != :republish
      end

      manual.removed_documents.each do |document|
        next if document.withdrawn? && action != :republish
        begin
          publishing_api_v2.unpublish(document.id, { type: "redirect", alternative_path: "/#{manual.slug}", discard_drafts: true })
        rescue GdsApi::HTTPNotFound
        end
        document.withdraw_and_mark_as_exported! if action != :republish
      end
    }
  end

  def publishing_api_draft_exporter
    ->(manual, action = nil) {
      patch_links = publishing_api_v2.method(:patch_links)
      put_content = publishing_api_v2.method(:put_content)
      organisation = organisation(manual.attributes.fetch(:organisation_slug))
      manual_renderer = ManualRenderer.create
      manual_document_renderer = ManualsPublisherWiring.get(:manual_document_renderer)

      ManualPublishingAPILinksExporter.new(
        patch_links, organisation, manual
      ).call

      ManualPublishingAPIExporter.new(
        put_content, organisation, manual_renderer, PublicationLog, manual
      ).call

      manual.documents.each do |document|
        next if !document.needs_exporting? && action != :republish

        ManualSectionPublishingAPILinksExporter.new(
          patch_links, organisation, manual, document
        ).call

        ManualSectionPublishingAPIExporter.new(
          put_content, organisation, manual_document_renderer, manual, document
        ).call
      end
    }
  end

  def publishing_api_withdrawer
    ->(manual, _ = nil) {
      PublishingAPIWithdrawer.new(
        publishing_api: publishing_api_v2,
        entity: manual,
      ).call

      manual.documents.each do |document|
        PublishingAPIWithdrawer.new(
          publishing_api: publishing_api_v2,
          entity: document,
        ).call
      end
    }
  end

  def publishing_api_v2
    ManualsPublisherWiring.get(:publishing_api_v2)
  end

  def organisation(slug)
    ManualsPublisherWiring.get(:organisation_fetcher).call(slug)
  end
end
