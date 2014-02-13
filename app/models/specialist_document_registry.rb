require "gds_api/panopticon"

class SpecialistDocumentRegistry

  def self.all
    Artefact.where(kind: 'specialist-document').desc(:updated_at).map do |artefact|
      self.fetch(artefact.id)
    end.compact
  end

  def self.fetch(id, version: nil)
    return nil unless Artefact.find(id)

    editions = SpecialistDocumentEdition.where(panopticon_id: id).order(:created_at)

    edition = if version
      editions.where(version_number: version).last
    else
      editions.last
    end

    return nil if edition.nil?

    SpecialistDocument.new(id: id, title: edition.title, summary: edition.summary, updated_at: edition.updated_at)
  end

  def self.store!(document)
    new(document).store!
  end

  def self.publish!(document)
    raise InvalidDocumentError.new("Can't publish a non-existant document", document) if document.id.nil?
    latest_edition = SpecialistDocumentEdition.where(panopticon_id: document.id).last

    unless latest_edition.published?
      latest_edition.emergency_publish
    end
  end

  def initialize(document)
    @document = document
  end

  def store!
    unless document.id
      response = create_artefact
      document.id = response['id']
    end

    update_edition
  rescue GdsApi::HTTPErrorResponse => e
    if e.code == 422
      errors = e.error_details['errors'].with_indifferent_access
      errors[:title] = errors.delete(:name)
      document.errors = errors
      raise InvalidDocumentError.new("Can't store an invalid document", document)
    else
      raise e
    end
  end

  class InvalidDocumentError < Exception
    def initialize(message, document)
      super(message)
      @document = document
    end

    attr_reader :document
  end

protected

  attr_reader :document

  def update_edition
    draft = find_or_create_draft
    draft.title = document.title
    draft.summary = document.summary
    draft.body = document.body

    draft.save!
  end

  def create_artefact
    panopticon_api.create_artefact!(name: document.title, slug: document.slug, kind: 'specialist-document', owning_app: 'specialist-publisher')
  end

  def panopticon_api
    @panopticon_api ||= GdsApi::Panopticon.new(Plek.current.find("panopticon"), CONTENT_API_CREDENTIALS)
  end

  def find_or_create_draft
    latest_edition = SpecialistDocumentEdition.where(panopticon_id: document.id).order(:created_at).last

    if latest_edition.nil?
      SpecialistDocumentEdition.new(panopticon_id: document.id, state: 'draft')
    else
      if latest_edition.published?
        SpecialistDocumentEdition.new(panopticon_id: document.id, state: 'draft', version_number: (latest_edition.version_number + 1))
      else
        latest_edition
      end
    end
  end

end
