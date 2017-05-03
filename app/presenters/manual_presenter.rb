require "govspeak_to_html_renderer"

class ManualPresenter
  attr_reader :manual

  def initialize(manual)
    @manual = manual
  end

  def title
    manual.title
  end

  def summary
    manual.summary
  end

  def body
    GovspeakToHTMLRenderer.create.call(manual).attributes.fetch(:body)
  end

  def valid?
    manual.valid?
  end

  def errors
    manual.errors
  end
end
