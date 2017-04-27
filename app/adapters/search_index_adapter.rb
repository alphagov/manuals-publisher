class SearchIndexAdapter
  def initialize
    @exporter = RummagerManualWithSectionsExporter.new
    @withdrawer = RummagerManualWithSectionsWithdrawer.new
  end

  def add(manual)
    @exporter.call(manual)
  end

  def remove(manual)
    @withdrawer.call(manual)
  end
end
