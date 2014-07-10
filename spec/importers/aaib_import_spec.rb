require "spec_helper"
require "specialist_document_bulk_importer"
require "aaib_import_mapper"
require "aaib_attachment_import_mapper"

require "features/support/panopticon_helpers"
require "webmock/rspec" # required for attachment_helpers
require "features/support/attachment_helpers"

RSpec.describe "AAIB import" do
  include PanopticonHelpers
  include AttachmentHelpers

  subject(:importer) {
    SpecialistDocumentBulkImporter.new(
      import_job_builder: import_job_builder,
      data_loader: data_loader,
    )
  }

  before do
    stub_out_panopticon
    stub_asset_manager
  end

  let(:import_job_builder) {
    ->(data) {
      SingleImport.new(
        document_creator: document_creator,
        logger: DocumentImportLogger.new(StringIO.new),
        data: data,
      )
    }
  }

  let(:data_loader) {
    ->(file) {
      JSON.parse(File.read(file))
    }
  }

  let(:document_creator) {
    AaibAttachmentImportMapper.new(
      import_mapper,
      repo,
      base_path
    )
  }

  let(:import_mapper) {
    AaibImportMapper.new(
      ->(attrs) {
        SpecialistPublisherWiring
        .get(:services)
        .create_aaib_report(attrs)
        .call
      }
    )
  }

  let(:base_path) { "spec/fixtures" }

  let(:files) {
    [
      "#{base_path}/import/metadata/99.json",
    ]
  }

  let(:report_title) { "2/1981 Cessna 414, G-BAOZ" }
  let(:report_asset_text) { "[2-1981 G-BAOZ.pdf](http://www.aaib.gov.uk/cms_resources/2-1981%20G-BAOZ.pdf)" }

  let(:repo) {
    SpecialistPublisherWiring.get(:aaib_report_repository)
  }

  let(:imported_report) { repo.all.first }

  context "with a successful import" do
    before do
      importer.call(files)
    end

    it "imports standard fields" do
      expect(imported_report.title).not_to be_empty
      expect(imported_report.body).not_to be_empty
    end

    it "attaches and replaces body text for assets" do
      expect(imported_report.attachments).not_to be_empty
      expect(imported_report.body).not_to include(report_asset_text)
    end
  end
end
