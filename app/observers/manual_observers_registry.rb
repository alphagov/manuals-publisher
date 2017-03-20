require "manual_publishing_api_exporter"
require "section_publishing_api_exporter"
require "publishing_api_withdrawer"
require "rummager_indexer"
require "formatters/manual_indexable_formatter"
require "formatters/section_indexable_formatter"
require "services"

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
    # Note that these should probably always be called with the :republish
    # action as 2nd argument, but we have to leave that up to the calling
    # service, rather than being able to encode it explicitly here.
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
          SectionIndexableFormatter.new(
            MarkdownAttachmentProcessor.new(section),
            manual,
          )
        )
      end

      manual.removed_documents.each do |section|
        indexer.delete(
          SectionIndexableFormatter.new(section, manual),
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
          SectionIndexableFormatter.new(
            MarkdownAttachmentProcessor.new(section),
            manual,
          )
        )
      end
    }
  end

  def publishing_api_publisher
    ->(manual, action = nil) {
      update_type = (action == :republish ? "republish" : nil)
      PublishingAPIPublisher.new(
        entity: manual,
        update_type: update_type,
      ).call

      manual.documents.each do |document|
        next if !document.needs_exporting? && action != :republish

        PublishingAPIPublisher.new(
          entity: document,
          update_type: update_type,
        ).call

        document.mark_as_exported! if action != :republish
      end

      manual.removed_documents.each do |document|
        next if document.withdrawn? && action != :republish
        begin
          publishing_api_v2.unpublish(document.id, type: "redirect", alternative_path: "/#{manual.slug}", discard_drafts: true)
        rescue GdsApi::HTTPNotFound # rubocop:disable Lint/HandleExceptions
        end
        document.withdraw_and_mark_as_exported! if action != :republish
      end
    }
  end

  def publishing_api_draft_exporter
    ->(manual, action = nil) {
      update_type = (action == :republish ? "republish" : nil)

      organisation = organisation(manual.attributes.fetch(:organisation_slug))

      ManualPublishingAPILinksExporter.new(
        organisation, manual
      ).call

      ManualPublishingAPIExporter.new(
        organisation, manual, update_type: update_type
      ).call

      manual.documents.each do |document|
        next if !document.needs_exporting? && action != :republish

        SectionPublishingAPILinksExporter.new(
          organisation, manual, document
        ).call

        SectionPublishingAPIExporter.new(
          organisation, manual, document, update_type: update_type
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
    Services.publishing_api_v2
  end

  def organisation(slug)
    OrganisationFetcher.instance.call(slug)
  end
end
