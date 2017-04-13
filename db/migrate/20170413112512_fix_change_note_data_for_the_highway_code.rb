class FixChangeNoteDataForTheHighwayCode < Mongoid::Migration
  def self.reset_change_note(section_slug, created_at)
    SectionEdition.where(
      slug: 'guidance/the-highway-code/' + section_slug,
      created_at: created_at
    ).each do |section_edition|
      section_edition.update_attributes!(change_note: nil, minor_update: true)
      edition_attributes = [
        section_edition.id,
        section_edition.title,
        section_edition.created_at
      ]
      puts "Updated SectionEdition with attributes: #{edition_attributes.join(', ')}"
    end
  end

  def self.up
    created_at_0925 = Time.parse('2017-03-01 09:25:48')
    created_at_1102 = Time.parse('2017-03-01 11:02:33')

    reset_change_note 'road-users-requiring-extra-care-204-to-225',
                      created_at_0925
    reset_change_note 'road-users-requiring-extra-care-204-to-225',
                      created_at_1102

    reset_change_note 'signals-to-other-road-users',
                      created_at_0925
    reset_change_note 'signals-to-other-road-users',
                      created_at_1102

    reset_change_note 'signals-by-authorised-persons',
                      created_at_0925
    reset_change_note 'signals-by-authorised-persons',
                      created_at_1102

    reset_change_note 'road-markings',
                      created_at_0925
    reset_change_note 'road-markings',
                      created_at_1102

    reset_change_note 'vehicle-markings',
                      created_at_0925
    reset_change_note 'vehicle-markings',
                      created_at_1102

    reset_change_note 'annex-8-safety-code-for-new-drivers',
                      created_at_0925
    reset_change_note 'annex-8-safety-code-for-new-drivers',
                      created_at_1102

    # The annex-5-penalties don't have a SectionEdition created at 09:25.
    # See https://github.com/alphagov/manuals-publisher/issues/861 for
    # further information
    reset_change_note 'annex-5-penalties',
                      created_at_1102
  end

  def self.down
    # We've intentionally left this blank.
    # While feasible to reconstruct the data we've decided against it given the time it'll take and that it's already bad data.
  end
end
