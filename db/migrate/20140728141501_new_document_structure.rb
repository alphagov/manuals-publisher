class NewDocumentStructure < Mongoid::Migration
  class OldEdition
    include Mongoid::Document
    store_in :specialist_document_editions
    field :extra_fields, type: Hash, default: {}
  end

  class NewDocument
    include Mongoid::Document
    store_in :document_records

    validates :document_id, presence: true
    validates :document_type, presence: true
    validates :slug, presence: true

    class Edition
      include Mongoid::Document
      validates :document_type, presence: true
      validates :slug, presence: true
    end

    class Attachment
      include Mongoid::Document
    end

    embeds_many :editions,
      class_name: "NewDocumentStructure::NewDocument::Edition",
      cascade_callbacks: true

    embeds_many :attachments,
      class_name: "NewDocumentStructure::NewDocument::Attachment",
      cascade_callbacks: true
  end

  def self.create_new_document(old_editions)
    document_id = old_editions.first.read_attribute("document_id")
    document_type = old_editions.first.read_attribute("document_type")
    slug = old_editions.first.read_attribute("slug")

    serialized_attachments = old_editions.last.attributes.fetch("attachments", [])
    serialized_editions = old_editions.map { |e| e.attributes.except("attachments") }

    puts "Migrating #{slug} #{document_id} size: #{serialized_editions.to_s.size}"

    new_doc = NewDocument.create!(
      document_id: document_id,
      document_type: document_type,
      slug: slug,
      editions: serialized_editions,
      attachments: serialized_attachments,
    )
  end

  def self.up
    OldEdition.all.distinct(:document_id).each do |document_id|
      editions_of_document = OldEdition
          .where(document_id: document_id)
          .order_by([:version_number, :desc])
          .to_a

      create_new_document(editions_of_document)
    end
  end

  def self.down
    raise IrreversibleMigration
  end
end
