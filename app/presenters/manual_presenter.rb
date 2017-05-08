class ManualPresenter
  def initialize(manual)
    @manual = manual
  end

  delegate :title, to: :@manual
  delegate :summary, to: :@manual
  delegate :valid?, to: :@manual
  delegate :errors, to: :@manual

  def body
    Govspeak::Document.new(@manual.body).to_html
  end
end
