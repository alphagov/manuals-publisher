require "govspeak_to_html_renderer"

class ManualRenderer
  def call(manual)
    GovspeakToHTMLRenderer.create.call(manual)
  end
end
