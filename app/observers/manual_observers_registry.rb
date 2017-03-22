require 'publication_logger'
require 'publishing_api_draft_manual_with_sections_exporter'
require 'publishing_api_manual_with_sections_publisher'
require 'rummager_manual_with_sections_exporter'
require 'rummager_manual_with_sections_withdrawer'
require 'publishing_api_manual_with_sections_withdrawer'

class ManualObserversRegistry
  def update
    [
      PublishingApiDraftManualWithSectionsExporter.new
    ]
  end
  alias_method :update_original_publication_date, :update

  def creation
    [
      PublishingApiDraftManualWithSectionsExporter.new
    ]
  end

  def withdrawal
    [
      PublishingApiManualWithSectionsWithdrawer.new,
      RummagerManualWithSectionsWithdrawer.new,
    ]
  end
end
