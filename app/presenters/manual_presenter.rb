require "govspeak_to_html_renderer"

class ManualPresenter
  attr_reader :manual

  def initialize(manual)
    @manual = manual
  end

  def call
    GovspeakToHTMLRenderer.create.call(manual)
  end
end
