class RummagerManualWithSectionsWithdrawer
  def call(manual)
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
