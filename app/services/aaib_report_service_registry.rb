require "specialist_publisher_wiring"

class AaibReportServiceRegistry
  def list
    ListDocumentsService.new(
      aaib_report_repository,
    )
  end

  def new
    NewDocumentService.new(
      aaib_report_builder,
    )
  end

  def create(attributes)
    CreateDocumentService.new(
      aaib_report_builder,
      aaib_report_repository,
      observers.aaib_report_creation,
      attributes,
    )
  end

  def show(document_id)
    ShowDocumentService.new(
      aaib_report_repository,
      document_id,
    )
  end

  def preview(document_id, attributes)
    PreviewDocumentService.new(
      aaib_report_repository,
      aaib_report_builder,
      document_renderer,
      document_id,
      attributes,
    )
  end

  def publish(document_id)
    PublishDocumentService.new(
      aaib_report_repository,
      observers.aaib_report_publication,
      document_id,
    )
  end

  def update(document_id, attributes)
    UpdateDocumentService.new(
      repo: aaib_report_repository,
      listeners: [],
      document_id: document_id,
      attributes: attributes,
    )
  end

  def withdraw(document_id)
    WithdrawDocumentService.new(
      aaib_report_repository,
      observers.aaib_report_withdrawal,
      document_id,
    )
  end

private
  def observers
    @observers ||= SpecialistPublisherWiring.get(:observers)
  end

  def aaib_report_repository
    SpecialistPublisherWiring.get(:aaib_report_repository)
  end

  def aaib_report_builder
    SpecialistPublisherWiring.get(:aaib_report_builder)
  end
end
