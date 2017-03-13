class RemoveSpecialistDocumentEditionsWithNonManualDocumentType < Mongoid::Migration
  def self.up
    SpecialistDocumentEdition.where(:document_type.ne => 'manual').delete_all
  end

  def self.down
    raise IrreversibleMigration
  end
end
