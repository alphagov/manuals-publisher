class Section::ReorderService
  def initialize(user:, manual_id:, section_order:)
    @user = user
    @manual_id = manual_id
    @section_order = section_order
  end

  def call
    manual = Manual.find(manual_id, user)
    manual.draft
    manual.reorder_sections(section_order)
    manual.save!(user)
    Publishing::DraftAdapter.save_draft_for_manual_and_sections(manual, include_sections: false)

    [manual, manual.sections]
  end

private

  attr_reader :user, :manual_id, :section_order
end
