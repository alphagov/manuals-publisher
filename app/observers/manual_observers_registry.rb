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
    [
      publication_logger,
      publishing_api_exporter,
      rummager_exporter,
    ]
  end

  def republication
    [
      publishing_api_exporter,
      rummager_exporter,
    ]
  end

  def update
    [
      publishing_api_draft_exporter
    ]
  end

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

  def publishing_api_exporter
    ->(manual, action = nil) {
      manual_renderer = ManualsPublisherWiring.get(:manual_renderer)
      ManualPublishingAPIExporter.new(
        publishing_api.method(:put_content_item),
        organisation(manual.attributes.fetch(:organisation_slug)),
        manual_renderer,
        PublicationLog,
        manual
      ).call

      document_renderer = ManualsPublisherWiring.get(:manual_document_renderer)
      manual.documents.each do |document|
        next if !document.needs_exporting? && action != :republish

        ManualSectionPublishingAPIExporter.new(
          publishing_api.method(:put_content_item),
          organisation(manual.attributes.fetch(:organisation_slug)),
          document_renderer,
          manual,
          document
        ).call

        document.mark_as_exported_to_live_publishing_api!
      end
    }
  end

  def publishing_api_draft_exporter
    ->(manual, _ = nil) {
      ManualPublishingAPILinksExporter.new(
        publishing_api_v2.method(:patch_links),
        organisation(manual.attributes.fetch(:organisation_slug)),
        manual
      ).call

      manual_renderer = ManualsPublisherWiring.get(:manual_renderer)
      ManualPublishingAPIExporter.new(
        publishing_api_v2.method(:put_content),
        organisation(manual.attributes.fetch(:organisation_slug)),
        manual_renderer,
        PublicationLog,
        manual
      ).call
    }
  end

  def publishing_api_withdrawer
    ->(manual, _ = nil) {
      PublishingAPIWithdrawer.new(
        publishing_api: publishing_api,
        entity: manual,
      ).call

      manual.documents.each do |document|
        PublishingAPIWithdrawer.new(
          publishing_api: publishing_api,
          entity: document,
        ).call
      end
    }
  end

  def publishing_api
    ManualsPublisherWiring.get(:publishing_api)
  end

  def publishing_api_v2
    ManualsPublisherWiring.get(:publishing_api_v2)
  end

  def organisation(slug)
    ManualsPublisherWiring.get(:organisation_fetcher).call(slug)
  end
end
