require "manual_publishing_api_exporter"
require "section_publishing_api_exporter"
require "publishing_api_withdrawer"
require "rummager_indexer"
require "formatters/manual_indexable_formatter"
require "formatters/section_indexable_formatter"
require "services"
require 'publication_logger'
require 'publishing_api_draft_manual_with_sections_exporter'
require 'publishing_api_manual_with_sections_publisher'

class ManualObserversRegistry
  def publication
    # The order here is important. For example content exporting
    # should happen before publishing to search.
    #
    # A draft export step follows publication logging as this ensures that
    # change notes that relate to the current draft are pushed straight to the
    # publishing API rather than on the subsequent draft-publish cycle.
    [
      PublicationLogger.new,
      PublishingApiDraftManualWithSectionsExporter.new,
      PublishingApiManualWithSectionsPublisher.new,
      rummager_exporter,
    ]
  end

  def republication
    # Note that these should probably always be called with the :republish
    # action as 2nd argument, but we have to leave that up to the calling
    # service, rather than being able to encode it explicitly here.
    [
      PublishingApiDraftManualWithSectionsExporter.new,
      PublishingApiManualWithSectionsPublisher.new,
      rummager_exporter,
    ]
  end

  def update
    [
      PublishingApiDraftManualWithSectionsExporter.new
    ]
  end
  alias_method :update_original_publication_date, :update

  def creation
    [
      PublishingApiDraftManualWithSectionsExporter.new
    ]
  end

  def withdrawal
    [
      publishing_api_withdrawer,
      rummager_withdrawer,
    ]
  end

private

  def rummager_exporter
    ->(manual, _ = nil) {
      indexer = RummagerIndexer.new

      indexer.add(
        ManualIndexableFormatter.new(manual)
      )

      manual.sections.each do |section|
        indexer.add(
          SectionIndexableFormatter.new(
            MarkdownAttachmentProcessor.new(section),
            manual,
          )
        )
      end

      manual.removed_sections.each do |section|
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

      manual.sections.each do |section|
        indexer.delete(
          SectionIndexableFormatter.new(
            MarkdownAttachmentProcessor.new(section),
            manual,
          )
        )
      end
    }
  end

  def publishing_api_withdrawer
    ->(manual, _ = nil) {
      PublishingAPIWithdrawer.new(
        entity: manual,
      ).call

      manual.sections.each do |document|
        PublishingAPIWithdrawer.new(
          entity: document,
        ).call
      end
    }
  end

  def publishing_api_v2
    Services.publishing_api_v2
  end
end
