# The history
# ===========
#
# The Homes and Communities Agency have a manual "The Capital Funding Guide"
# that they wanted to make extensive revisions to.  Removing sections
# wasn't possible when they made their changes so they created a new version of
# the manual at a new slug and worked on that.  They asked if we could remove
# the existing one and move the new one onto that old slug.  That wasn't easy
# so we issued some redirects to send visits to the old slug over to the
# new one.  Now that we're ready to tidy this up, we are planning to remove
# the existing manual (with unpublishings and gones via the publishing-api)
# and then reslug the new manual back onto the old slug and republish it.
#
# We also need to remove another draft manual that was created with the same
# slug as the old one.  It's not been published or edited much, so we can
# just delete it.  This document has slug "guidance/capital-funding-guide"
# and id: 7228d773-a416-4ec1-9549-5fb91b1caaf5
require "manual_relocator"
require "cli_manual_deleter"
require "stringio"

class RemoveRedirectCapitalFundingGuide < Mongoid::Migration
  def self.up
    bad_manual_id = "7228d773-a416-4ec1-9549-5fb91b1caaf5"
    manual_slug = "guidance/capital-funding-guide"
    new_manual_slug = "#{manual_slug}-hca"

    puts "Removing bad manual #{bad_manual_id} at #{manual_slug}."
    CliManualDeleter.new(manual_slug, manual_id: bad_manual_id, stdin: StringIO.new("y")).call

    puts "Removing existing manual #{manual_slug} and reslugging #{new_manual_slug} back onto it."
    ManualRelocator.move(new_manual_slug, manual_slug)
  end

  def self.down
    # Whilst it would be possible to reverse this, it would be a lot of work
    # for something that is unlikely to ever get run.
    raise IrreversibleMigration
  end
end
