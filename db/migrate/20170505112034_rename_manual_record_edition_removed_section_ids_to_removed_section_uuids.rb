class RenameManualRecordEditionRemovedSectionIdsToRemovedSectionUuids < Mongoid::Migration
  def self.up
    ManualRecord::Edition.all.each do |manual_record_edition|
      manual_record_edition.rename(:removed_section_ids, :removed_section_uuids)
    end
  end

  def self.down
    ManualRecord::Edition.all.each do |manual_record_edition|
      manual_record_edition.rename(:removed_section_uuids, :removed_section_ids)
    end
  end
end
