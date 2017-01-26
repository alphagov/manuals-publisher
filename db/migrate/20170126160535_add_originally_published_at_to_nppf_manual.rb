# The history
# -----------
#
# In the previous migration we change the manual with slug
# guidance/national-planning-policy-framework to have a public timestamp of
# 23 March 2012.  We didn't persist this information in our DB because there
# was no functionality for that.  Now that there is, we update the DB to pretend
# the migration update was done via the UI.
class AddOriginallyPublishedAtToNppfManual < Mongoid::Migration
  def self.up
    original_publication_timestamp = Date.new(2012, 3, 27).to_time
    manual = ManualRecord.find_by(slug: "guidance/national-planning-policy-framework")
    latest, *others = manual.editions.sort_by(&:version_number).reverse
    others.each do |edition|
      edition.originally_published_at = original_publication_timestamp
      edition.use_originally_published_at_for_public_timestamp = true
      edition.save
    end
    latest.originally_published_at = original_publication_timestamp
    # ideally we'd set this to false because we don't want future
    # updates to keep the public_updated_at timestamp set to 2012, but
    # if this is published and we set it to false then republishing this
    # edition wouldn't set it correctly which is bad.  If it's a draft
    # however then we'd rather it did the least surprising thing for users
    # which is to not use the originally published at timestamp for the
    # next major edition
    latest.use_originally_published_at_for_public_timestamp = (latest.state == "published")
    latest.save
  end

  def self.down
    # It's possible to reverse this, but it's meaningless to do so as it leaves
    # the data broken, so we're making this irreversible too
    raise IrreversibleMigration
  end
end
