class RummagerManualWithSectionsWithdrawer
  def call(manual, _ = nil)
    indexer = RummagerIndexer.new

    indexer.delete(
      ManualIndexableFormatter.new(manual)
    )

    manual.sections.each do |section|
      indexer.delete(
        SectionIndexableFormatter.new(
          MarkdownAttachmentProcessor.new(section),
          manual,
        )
      )
    end
  end
end
