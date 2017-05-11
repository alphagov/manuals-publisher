class PublishingApiManualWithSectionsWithdrawer
  def call(manual, _ = nil)
    PublishingAPIWithdrawer.new.call(entity: manual)

    manual.sections.each do |section|
      PublishingAPIWithdrawer.new.call(entity: section)
    end
  end
end
