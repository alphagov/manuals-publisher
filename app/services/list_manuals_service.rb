class ListManualsService
  def initialize(manual_repository:, context:)
    @manual_repository = manual_repository
    @context = context
  end

  def call
    Manual.all(context.current_user)
  end

private

  attr_reader :manual_repository, :context
end
