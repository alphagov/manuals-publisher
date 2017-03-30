class ListManualsService
  def initialize(context:)
    @context = context
  end

  def call
    Manual.all(context.current_user)
  end

private

  attr_reader :context
end
