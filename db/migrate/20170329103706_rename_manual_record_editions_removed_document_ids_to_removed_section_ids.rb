class RenameManualRecordEditionsRemovedDocumentIdsToRemovedSectionIds < Mongoid::Migration
  def self.up
    ManualRecord::Edition.collection.update(
      {},
      { '$rename' => { 'removed_document_ids' => 'removed_section_ids' } },
      { multi: true }
    )
  end

  def self.down
    ManualRecord::Edition.collection.update(
      {},
      { '$rename' => { 'removed_section_ids' => 'removed_document_ids' } },
      { multi: true }
    )
  end
end
