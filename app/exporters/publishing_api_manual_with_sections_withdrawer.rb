class PublishingApiManualWithSectionsWithdrawer
  def call(manual, _ = nil)
    PublishingAPIWithdrawer.new(
      entity: manual,
    ).call

    manual.sections.each do |document|
      PublishingAPIWithdrawer.new(
        entity: document,
      ).call
    end
  end
end
