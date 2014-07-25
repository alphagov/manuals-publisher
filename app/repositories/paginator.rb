class RepositoryPaginator
  def initialize(repo)
    @repo = repo
    @pipeline = []
  end

  def [](offset, limit)
    apply_pipeline(repo.all(limit, offset))
  end

  lazy_methods = %i(
    chunk
    drop
    drop_while
    map
    reject
    select
    take
    take_while
    zip
  )

  lazy_methods.each do |m|
    define_method(m) do |*args, &block|
      pipeline.push([m, args, block])

      self
    end
  end

  def count
    repo.count
  end

private

  attr_reader :repo, :pipeline

  def apply_pipeline(results)
    pipeline.reduce(results) { |collection, (op, args, func)|
      collection.public_send(op, *args, &func)
    }
  end
end
