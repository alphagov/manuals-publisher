class ManualUpdateType
  def self.for(manual)
    new(manual).update_type
  end

  def initialize(manual)
    @manual = manual
  end

  def update_type
    # The first edition to be sent to the publishing api must always be sent as
    # a major update
    return "major" unless manual.has_ever_been_published?

    # Otherwise our update type status depends on the update type status
    # of our children if any of them are major we are major (and they
    # have to send a major for their first edition too).
    all_documents_are_minor? ? "minor" : "major"
  end

private

  attr_reader :manual

  def all_documents_are_minor?
    manual.
      sections.
      select(&:needs_exporting?).
      all? { |d|
        d.minor_update? && d.has_ever_been_published?
      }
  end
end
