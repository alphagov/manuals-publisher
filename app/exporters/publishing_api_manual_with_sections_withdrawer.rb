class PublishingApiManualWithSectionsWithdrawer
  def call(manual, _ = nil)
    PublishingAPIWithdrawer.new(
      entity: manual,
    ).call

    manual.sections.each do |section|
      PublishingAPIWithdrawer.new(
        entity: section,
      ).call
    end
  end
end
