require "delegate"

class ChangeNoteValidator < SimpleDelegator
  def initialize(section)
    @section = section
    reset_errors
    super(section)
  end

  def valid?
    reset_errors
    section_valid = section.valid?
    change_note_ok = (change_note_not_required? || change_note_provided?)
    unless change_note_ok
      add_errors
    end

    section_valid && change_note_ok
  end

  def errors
    section.errors.to_hash.merge(@errors)
  end

private

  attr_reader :section

  def change_note_not_required?
    never_published? || minor_update?
  end

  def change_note_provided?
    if change_note.present?
      true
    else
      false
    end
  end

  def reset_errors
    @errors = {}
  end

  def add_errors
    @errors[:change_note] ||= []
    @errors[:change_note].push(change_note_error)
  end

  def change_note_error
    "You must provide a change note or indicate minor update"
  end
end
