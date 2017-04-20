class Manual::ListService
  def initialize(context:)
    @context = context
  end

  def call
    Manual.all(context.current_user, load_associations: false)
  end

private

  attr_reader :context
end
