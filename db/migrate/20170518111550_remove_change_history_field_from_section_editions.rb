class RemoveChangeHistoryFieldFromSectionEditions < Mongoid::Migration
  def self.up
    SectionEdition.update_all('$unset' => { 'change_history' => true })
  end

  def self.down
    raise IrreversibleMigration
  end
end
