require "manuals_republisher"

class ChangeChangeNotesForMotInspectionManual < Mongoid::Migration
  def self.up
    changes = [
      { title: "4. Lamps, reflectors and electrical equipment", change: "", slug: "guidance/mot-inspection-manual-for-private-passenger-and-light-commercial-vehicles/4-lamps-reflectors-and-electrical-equipment" },
      { title: "4.1.5 Headlamps - Levelling devices", change: "Sentence added 'The check of headlamp levelling devices does not apply to motor caravans'.", slug: "guidance/mot-inspection-manual-for-private-passenger-and-light-commercial-vehicles/4-lamps-reflectors-and-electrical-equipment" },
      { title: "4.2.2 Front and rear position lamps, daytime running lamps and end-outline marker lamps - Switching", change: "Sentence added 'Military vehicles may have a multi-position switch which cannot turn the front and rear position lamps on with a single operation of the switch. This should not be regarded as a defect'.", slug: "guidance/mot-inspection-manual-for-private-passenger-and-light-commercial-vehicles/4-lamps-reflectors-and-electrical-equipment" },
      { title: "4.4.1 Direction indicators and hazard warning lamps - Presence, condition and operation", change: "Sentence added 'Direction indicators that function sequentially/dynamically are not to be considered a reason to fail'.", slug: "guidance/mot-inspection-manual-for-private-passenger-and-light-commercial-vehicles/4-lamps-reflectors-and-electrical-equipment" },
      { title: "4.4.3 Direction indicators and hazard warning lamps - Compliance with requirements", change: "Sentence added 'Direction indicators that function sequentially/dynamically are not to be considered a reason to fail'.", slug: "guidance/mot-inspection-manual-for-private-passenger-and-light-commercial-vehicles/4-lamps-reflectors-and-electrical-equipment" },
      { title: "4.6.1 Reversing lamps - Condition and operation", change: "Sentence changed from 'You must inspect all reversing lamps fitted to vehicles first used from 1 September 2009' to 'You must inspect all reversing lamps fitted to vehicles first used from 1 September 2009 other than quadricycles and Class 3 vehicles'.", slug: "guidance/mot-inspection-manual-for-private-passenger-and-light-commercial-vehicles/4-lamps-reflectors-and-electrical-equipment" },
      { title: "4.6.2 Reversing lamps - Compliance with requirements", change: "Sentence changed from 'You must inspect all reversing lamps fitted to vehicles first used from 1 September 2009' to 'You must inspect all reversing lamps fitted to vehicles first used from 1 September 2009 other than quadricycles and Class 3 vehicles'.", slug: "guidance/mot-inspection-manual-for-private-passenger-and-light-commercial-vehicles/4-lamps-reflectors-and-electrical-equipment" },
      { title: "4.6.3 Reversing lamps - Switching", change: "Sentence changed from 'You must inspect all reversing lamps fitted to vehicles first used from 1 September 2009' to 'You must inspect all reversing lamps fitted to vehicles first used from 1 September 2009 other than quadricycles and Class 3 vehicles'.", slug: "guidance/mot-inspection-manual-for-private-passenger-and-light-commercial-vehicles/4-lamps-reflectors-and-electrical-equipment" },
      { title: "4.8.1 Rear reflectors - Presence, condition and operation", change: "Sentence changed from 'You must inspect the 2 mandatory rear reflectors that must be fitted' to 'You must inspect the 2 mandatory red rear reflectors that must be fitted'.", slug: "guidance/mot-inspection-manual-for-private-passenger-and-light-commercial-vehicles/4-lamps-reflectors-and-electrical-equipment" },
      { title: "4.8.2 Rear reflectors - Compliance with requirements", change: "Sentence changed from 'You must inspect the 2 mandatory rear reflectors that must be fitted' to 'You must inspect the 2 mandatory red rear reflectors that must be fitted'.", slug: "guidance/mot-inspection-manual-for-private-passenger-and-light-commercial-vehicles/4-lamps-reflectors-and-electrical-equipment" },
      { title: "4.11 Electrical wiring", change: "Sentence added 'This inspection does not apply to electrical wiring to brake pads'.", slug: "guidance/mot-inspection-manual-for-private-passenger-and-light-commercial-vehicles/4-lamps-reflectors-and-electrical-equipment" },
      { title: "5. Axles, wheels, tyres and suspension", change: "", slug: "guidance/mot-inspection-manual-for-private-passenger-and-light-commercial-vehicles/5-axles-wheels-tyres-and-suspension" },
      { title: "5.3.4 Axles, wheels, tyres and suspension", change: "Suspension joints, pins and bushes. Added item 4 to method of inspection 'Use an assistant to shake the wheels as per item 3, whilst observing the relevant components'.", slug: "guidance/mot-inspection-manual-for-private-passenger-and-light-commercial-vehicles/5-axles-wheels-tyres-and-suspension" },
      { title: "8. Nuisance", change: "", slug: "guidance/mot-inspection-manual-for-private-passenger-and-light-commercial-vehicles/8-nuisance" },
      { title: "8.2.2.2 Opacity", change: "Added a new heading and information 'Vehicles fitted with a different engine'.", slug: "guidance/mot-inspection-manual-for-private-passenger-and-light-commercial-vehicles/8-nuisance" },
      { title: "8.2.2.2 Opacity", change: "Added a new heading and information 'Kit cars'.", slug: "guidance/mot-inspection-manual-for-private-passenger-and-light-commercial-vehicles/8-nuisance" },
      { title: "Appendix C: Seat belt fitment tables", change: "", slug: "guidance/mot-inspection-manual-for-private-passenger-and-light-commercial-vehicles/appendix-c-seat-belt-fitment-tables" },
      { title: "Table 3. Rear seat belts", change: "Seat belt type 'R' changed from 'Any of the following' to 'In forward and rearward facing rear seats any of the following'.", slug: "guidance/mot-inspection-manual-for-private-passenger-and-light-commercial-vehicles/appendix-c-seat-belt-fitment-tables" },
    ]

    changes.each do |change_data|
      publication_log = PublicationLog.new
      publication_log.title = change_data[:title]
      change_note = change_data[:change].length.positive? ? "#{change_data[:title]} - #{change_data[:change]}" : ""
      publication_log.change_note = change_note
      publication_log.slug = change_data[:slug]
      publication_log.version_number = PublicationLog.where(slug: change_data[:slug]).count + 1
      publication_log.save
      if publication_log.errors.any?
        raise StandardError, "Error: #{publication_log.errors}"
      end

      publication_log.created_at = "2019-10-30T16:42:58Z".to_datetime
      publication_log.updated_at = "2019-10-30T16:42:58Z".to_datetime
      publication_log.save(validate: false)
    end

    logger = Logger.new(STDOUT)
    logger.formatter = Logger::Formatter.new
    user = User.find_by(email: "oscar.wyatt@digital.cabinet-office.gov.uk")
    manual = Manual.find("82676c67-7334-4d4d-90af-023e6237e4d9", user)
    republisher = ManualsRepublisher.new(logger)
    republisher.execute([manual])
  end

  def self.down; end
end
