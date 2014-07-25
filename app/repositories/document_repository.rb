require "fetchable"

class DocumentRepository
  include Fetchable

  NotFoundError = Module.new

  def fetch(*args, &block)
    super
  rescue KeyError => e
    raise e.extend(NotFoundError)
  end

  def initialize(dependencies)
    @collection = dependencies.fetch(:collection)
    @document_factory = dependencies.fetch(:document_factory)
  end

  def [](id)
    record = collection.find_by(document_id: id)

    build_document(record) if record
  end

  def all(limit = count, offset = 0)
    collection
      .all_by_updated_at(limit, offset)
      .lazy
      .map(&method(:build_document))
  end
  alias_method :all_by_updated_at_desc, :all

  def store(document)
    record = collection.find_or_initialize_by(document_id: document.id)

    # TODO What do we want to denormalise?
    record.attributes = {
      slug: document.slug,
      document_type: document.document_type,
    }

    edition = record.new_or_existing_draft_edition
    edition.attributes = attributes_for(document)

    # TODO We should handle setting currently published editions to archived
    # through a PublishedDocumentRepository instead of this hack.
    sync_edition_states(document, record)

    record.save!
  end

  def slug_unique?(document)
    collection.slug_taken_by_another_document?(document.slug, document.id)
  end

  def count
    collection.count
  end

private
  attr_reader :collection, :document_factory

  def build_document(record)
    document_factory.call(
      record.document_id,
      record.editions.last(2),
    )
  end

  def attributes_for(document)
    # TODO Some of these shouldn't be on editions (document_type and slug)
    {
      title: document.title,
      summary: document.summary,
      body: document.body,
      slug: document.slug,
      extra_fields: document.extra_fields,
      document_type: document.document_type,
      attachments: document.attachments,
      change_note: document.change_note,
      minor_update: document.minor_update,
    }
  end

  def sync_edition_states(document, record)
    record_editions = record.editions.last(document.editions.count)

    record_editions.zip(document.editions).each do |record_edition, document_edition|
      record_edition.state = document_edition.state
    end
  end
end
