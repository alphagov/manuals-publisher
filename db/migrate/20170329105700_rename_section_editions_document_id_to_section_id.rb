class RenameSectionEditionsDocumentIdToSectionId < Mongoid::Migration
  def self.up
    SectionEdition.collection.update(
      {},
      { '$rename' => { 'document_id' => 'section_id' } },
      { multi: true }
    )
  end

  def self.down
    SectionEdition.collection.update(
      {},
      { '$rename' => { 'section_id' => 'document_id' } },
      { multi: true }
    )
  end
end
