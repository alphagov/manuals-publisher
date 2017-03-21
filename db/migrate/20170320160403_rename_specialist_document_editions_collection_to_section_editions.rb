class RenameSpecialistDocumentEditionsCollectionToSectionEditions < Mongoid::Migration
  def self.up
    rename_collection('specialist_document_editions', 'manual_section_editions')
  end

  def self.down
    rename_collection('manual_section_editions', 'specialist_document_editions')
  end

  def self.rename_collection(source, target)
    db = Mongoid.database
    if db.collection_names.include?(target)
      if db.collection(target).count == 0
        db.drop_collection(target)
      else
        raise "Unexpected non-empty collection: #{target}"
      end
    end
    db.rename_collection(source, target)
  end
end
