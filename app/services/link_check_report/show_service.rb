class LinkCheckReport::ShowService
  def initialize(id:)
    @id = id
  end

  def call
    LinkCheckReport.find(id)
  end

private

  attr_reader :id
end
