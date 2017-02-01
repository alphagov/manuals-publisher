class GovspeakHtmlConverter
  def self.create
    ->(string) {
      Govspeak::Document.new(string).to_html
    }
  end
end
