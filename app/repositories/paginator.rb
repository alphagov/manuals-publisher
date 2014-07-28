class RepositoryPaginator
  def initialize(repo)
    @repo = repo
    @drop = 0
    @take = 0
    @pipeline = []
  end

  def [](offset, limit)
    apply_pipeline(repo.all(limit, offset))
  end

  def to_a
    self[@drop, @drop + @take]
  end

  def drop(n)
    @drop += n

    self
  end

  def take(n)
    @take = n

    self
  end

  lazy_methods = %i(
    chunk
    map
    reject
    select
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

  def size
    count
  end

private

  attr_reader :repo, :pipeline

  def apply_pipeline(results)
    pipeline.reduce(results) { |collection, (op, args, func)|
      collection.public_send(op, *args, &func)
    }
  end
end
