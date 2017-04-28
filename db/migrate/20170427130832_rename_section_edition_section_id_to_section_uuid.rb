class RenameSectionEditionSectionIdToSectionUuid < Mongoid::Migration
  def self.up
    SectionEdition.all.each do |section_edition|
      section_edition.rename(:section_id, :section_uuid)
    end
  end

  def self.down
    SectionEdition.all.each do |section_edition|
      section_edition.rename(:section_uuid, :section_id)
    end
  end
end
