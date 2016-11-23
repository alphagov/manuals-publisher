# The history
# ===========
#
# ManualRecord embeds the editions, however a handful of the manuals have
# so many editions that they are starting to butt up against the 16Mb document
# size limit in our versio of mongo.  This means users can't make changes and
# get strange behaviour from the system.
#
# To get around this and keep the API as simple as possible we turn the
# `embeds_many` association on ManualRecord into a `has_many` association
# and move all the existing editions out of ManualRecord's collection and
# into their own collection.
class MoveManualRecordEditionsToOwnCollection < Mongoid::Migration
  def self.up
    manual_records_collection = Mongoid.database.collection("manual_records")
    manual_record_editions_collection = Mongoid.database.collection("manual_record_editions")
    manual_records_collection.find.each do |manual_record|
      editions = manual_record["editions"]
      puts "Migrating #{editions.count} editions for #{manual_record["manual_id"]}:#{manual_record["slug"]}"
      editions.each do |edition|
        edition["manual_record_id"] = manual_record["_id"]
        edition["manual_id"] = manual_record["manual_id"]
        manual_record_editions_collection.insert edition
      end
    end

    manual_records_collection.update({}, {:'$unset' => {editions: 1}}, multi: true)
  end

  def self.down
    # Whilst it would be possible to reverse this, it would be a lot of work
    # for something that is unlikely to ever get run.
    raise IrreversibleMigration
  end
end
