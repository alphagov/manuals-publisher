class Organisation
  attr_accessor :title, :abbreviation, :content_id, :web_url

  def initialize(attributes = {})
    @title = attributes[:title]
    @abbreviation = attributes[:abbreviation]
    @content_id = attributes[:content_id]
    @web_url = attributes[:web_url]
  end
end
