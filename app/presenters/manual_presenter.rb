require "govspeak_to_html_renderer"

class ManualPresenter
  attr_reader :manual

  def initialize(manual)
    @manual = manual
  end

  def call
    GovspeakToHTMLRenderer.create.call(manual)
  end

  def title
    call.attributes.fetch(:title)
  end

  def summary
    call.attributes.fetch(:summary)
  end

  def body
    call.attributes.fetch(:body)
  end
end
