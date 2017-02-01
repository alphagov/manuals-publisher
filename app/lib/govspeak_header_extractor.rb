class GovspeakHeaderExtractor
  def self.create
    ->(string) {
      Govspeak::Document.new(string).structured_headers
    }
  end
end
