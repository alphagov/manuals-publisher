require "govspeak_to_html_renderer"

class ManualRenderer
  def self.create
    ->(manual) {
      GovspeakToHTMLRenderer.create.call(manual)
    }
  end
end
