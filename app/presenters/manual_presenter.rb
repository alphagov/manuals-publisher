require "govspeak_to_html_renderer"

class ManualPresenter
  attr_reader :manual

  def initialize(manual)
    @manual = manual
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

  def valid?
    manual.valid?
  end

  def errors
    manual.errors
  end

private

  def call
    GovspeakToHTMLRenderer.create.call(manual)
  end
end
