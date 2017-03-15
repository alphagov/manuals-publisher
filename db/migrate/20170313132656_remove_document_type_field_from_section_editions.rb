class RemoveDocumentTypeFieldFromSectionEditions < Mongoid::Migration
  def self.up
    SectionEdition.collection.update(
      {},
      { '$unset' => { 'document_type' => true } },
      { multi: true }
    )
  end

  def self.down
    raise IrreversibleMigration
  end
end
