class RenameManualRecordEditionSectionIdsToSectionUuids < Mongoid::Migration
  def self.up
    ManualRecord::Edition.all.each do |manual_record_edition|
      manual_record_edition.rename(:section_ids, :section_uuids)
    end
  end

  def self.down
    ManualRecord::Edition.all.each do |manual_record_edition|
      manual_record_edition.rename(:section_uuids, :section_ids)
    end
  end
end
