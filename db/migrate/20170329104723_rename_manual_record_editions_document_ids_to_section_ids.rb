class RenameManualRecordEditionsDocumentIdsToSectionIds < Mongoid::Migration
  def self.up
    ManualRecord::Edition.collection.update(
      {},
      { '$rename' => { 'document_ids' => 'section_ids' } },
      { multi: true }
    )
  end

  def self.down
    ManualRecord::Edition.collection.update(
      {},
      { '$rename' => { 'section_ids' => 'document_ids' } },
      { multi: true }
    )
  end
end
