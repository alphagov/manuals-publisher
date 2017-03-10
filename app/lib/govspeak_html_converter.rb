class GovspeakHtmlConverter
  def call(string)
    Govspeak::Document.new(string).to_html
  end
end
