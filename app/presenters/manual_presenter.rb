class ManualPresenter
  def initialize(manual)
    @manual = manual
  end

  def title
    manual.title
  end

  def summary
    manual.summary
  end

  def body
    GovspeakHtmlConverter.new.call(manual.body)
  end

  def valid?
    manual.valid?
  end

  def errors
    manual.errors
  end

private

  attr_reader :manual
end
