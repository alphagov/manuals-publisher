require "delegate"

class ChangeNoteValidator < SimpleDelegator
  def initialize(section)
    super(section)
  end
end
