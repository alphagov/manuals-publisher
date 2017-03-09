class RemoveSpecialistDocumentEditionsWithNonManualDocumentType < Mongoid::Migration
  def self.up
    SpecialistDocumentEdition.where(:document_type.ne => SpecialistDocumentEdition::MANUAL_DOCUMENT_TYPE).delete_all
  end

  def self.down
    raise IrreversibleMigration
  end
end
