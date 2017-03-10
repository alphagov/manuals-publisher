class GovspeakHeaderExtractor
  def call(string)
    Govspeak::Document.new(string).structured_headers
  end
end
