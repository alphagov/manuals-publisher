class RemoveExtraFieldsFieldFromSectionEditions < Mongoid::Migration
  def self.up
    SectionEdition.update_all('$unset' => { 'extra_fields' => true })
  end

  def self.down
    raise IrreversibleMigration
  end
end
