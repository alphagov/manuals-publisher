class ManualPresenter
  def initialize(manual)
    @manual = manual
  end

  delegate :title, to: :@manual
  delegate :summary, to: :@manual
  delegate :valid?, to: :@manual
  delegate :errors, to: :@manual

  def body
    GovspeakHtmlConverter.new.call(@manual.body)
  end
end
