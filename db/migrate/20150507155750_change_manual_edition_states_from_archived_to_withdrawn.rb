class ChangeManualEditionStatesFromArchivedToWithdrawn < Mongoid::Migration
  def self.up
    ManualRecord.all.each do |manual_record|
      manual_record.editions.where(state: "archived").each do |edition|
        edition.update_attribute(:state, "withdrawn")
      end
    end
  end

  def self.down
    raise IrreversibleMigration
  end
end
