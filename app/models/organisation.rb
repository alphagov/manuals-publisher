class Organisation
  attr_reader :title
  attr_reader :abbreviation
  attr_reader :content_id
  attr_reader :web_url

  def initialize(attributes = {})
    @title = attributes[:title]
    @abbreviation = attributes[:abbreviation]
    @content_id = attributes[:content_id]
    @web_url = attributes[:web_url]
  end
end
