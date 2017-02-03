class ListManualsService
  def initialize(manual_repository:, context:)
    @manual_repository = manual_repository
    @context = context
  end

  def call
    manual_repository.all
  end

  private

  attr_reader :manual_repository, :context
end
