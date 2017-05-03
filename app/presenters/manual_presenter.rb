require "govspeak_to_html_renderer"

class ManualPresenter
  def call(manual)
    GovspeakToHTMLRenderer.create.call(manual)
  end
end
