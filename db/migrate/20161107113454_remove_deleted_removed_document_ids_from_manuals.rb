# The history
# ===========
#
# In the past we have run various scripts and migrations to remove sections
# from some manuals.  The ids of these documents live in the
# removed_document_ids field of the ManualRecord::Edition.
# In some cases we've also totally removed the SpecialistDocumentEditions that
# these document ids refer to.  This causes a problem when trying to do
# a republishing, or any other bulk operations on these manuals.
#
# This migration searches through all the manuals and all their editions
# to delete any ids in the removed_document_ids that no longer refer to a
# SpecialistDocumentEdition.
#
# This seems dangerous as those document ids might refer to published content
# in the publishing-api, but we've checked all this manually and none of them
# did.
class RemoveDeletedRemovedDocumentIdsFromManuals < Mongoid::Migration
  def self.up
    ManualRecord.all.to_a.each do |manual_record|
      puts %{Looking at "#{manual_record.slug}":#{manual_record.manual_id}}
      manual_record.editions.each do |manual_edition|
        print "  Version: #{manual_edition.version_number} - "
        to_remove = (manual_edition.removed_document_ids || []).reject do |id|
          SpecialistDocumentEdition.where(document_id: id).exists?
        end
        if to_remove.size > 0
          puts "#{to_remove.size} entries to remove: #{to_remove.inspect}"
          manual_edition.removed_document_ids = (manual_edition.removed_document_ids - to_remove)
          manual_edition.save!
        else
          puts "Nothing to do!"
        end
      end
    end
  end

  def self.down
    # Whilst it would be possible to reverse this, it would be a lot of work
    # for something that is unlikely to ever get run.
    raise IrreversibleMigration
  end
end
