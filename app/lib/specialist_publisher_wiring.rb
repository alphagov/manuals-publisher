require "aaib_report_indexable_formatter"
require "builders/aaib_report_builder"
require "builders/cma_case_builder"
require "builders/international_development_fund_builder"
require "builders/manual_document_builder"
require "cma_case_indexable_formatter"
require "dependency_container"
require "finder_api"
require "finder_api_notifier"
require "gds_api_proxy"
require "gds_api/rummager"
require "id_generator"
require "manual_database_exporter"
require "marshallers/document_association_marshaller"
require "null_finder_schema"
require "panopticon_registerer"
require "rendered_specialist_document"
require "rummager_indexer"
require "specialist_document_attachment_processor"
require "specialist_document_database_exporter"
require "specialist_document_govspeak_to_html_renderer"
require "specialist_document_header_extractor"
require "validators/aaib_report_validator"
require "validators/change_note_validator"
require "validators/cma_case_validator"
require "validators/international_development_fund_validator"
require "validators/manual_document_validator"
require "validators/slug_uniqueness_validator"

$LOAD_PATH.unshift(File.expand_path("../..", "app/services"))

SpecialistPublisherWiring = DependencyContainer.new do
  define_factory(:services) {
    ServiceRegistry.new(
      document_renderer: get(:specialist_document_renderer),
      manual_repository_factory: get(:manual_repository_factory),
      manual_document_builder: get(:manual_document_builder),
    )
  }

  define_factory(:manual_builder) {
    ->(attrs) {
      slug_generator = SlugGenerator.new(prefix: "guidance")

      default = {
        id: IdGenerator.call,
        slug: slug_generator.call(attrs.fetch(:title)),
        summary: "",
        state: "draft",
        organisation_slug: "",
        updated_at: "",
      }

      ManualWithDocuments.new(
        get(:manual_document_builder),
        Manual.new(default.merge(attrs)),
        documents: [],
      )
    }
  }

  define_singleton(:aaib_report_repository) do
    DocumentRepository.new(
      collection: DocumentRecord.where(document_type: "aaib_report"),
      document_factory: get(:validatable_aaib_report_factory),
    )
  end

  define_singleton(:cma_case_repository) do
    DocumentRepository.new(
      collection: DocumentRecord.where(document_type: "cma_case"),
      document_factory: get(:validatable_cma_case_factory),
    )
  end

  define_singleton(:international_development_fund_repository) do
    DocumentRepository.new(
      collection: DocumentRecord.where(document_type: "international_development_fund"),
      document_factory: get(:validatable_international_development_fund_factory),
    )
  end

  define_singleton(:manual_specific_document_repository_factory) do
    ->(manual) {
      document_factory = get(:validated_manual_document_factory_factory).call(manual)

      DocumentRepository.new(
        collection: DocumentRecord.where(document_type: "manual"),
        document_factory: document_factory,
      )
    }
  end

  define_factory(:manual_repository_factory) {
    ->(organisation_slug) {
      get(:plain_manual_repository_factory).call(
        organisation_slug: organisation_slug,
        association_marshallers: [
          DocumentAssociationMarshaller.new(
            manual_specific_document_repository_factory: get(:manual_specific_document_repository_factory),
            decorator: ->(manual, attrs) {
              ManualWithDocuments.new(
                get(:manual_document_builder),
                manual,
                attrs,
              )
            }
          ),
        ],
      )
    }
  }

  define_factory(:manual_repository) {
    ManualRepository.new(
      {
        association_marshallers: [
          DocumentAssociationMarshaller.new(
            manual_specific_document_repository_factory: get(:manual_specific_document_repository_factory),
            decorator: ->(manual, attrs) {
              ManualWithDocuments.new(
                get(:manual_document_builder),
                manual,
                attrs,
              )
            }
          ),
        ],
        factory: Manual.method(:new),
        collection: ManualRecord,
      }
    )
  }

  define_factory(:plain_manual_repository_factory) {
    ->(dependencies) {
      ManualRepository.new(
        {
          association_marshallers: [],
          factory: Manual.method(:new),
          collection: ManualRecord.find_by_organisation(
            dependencies.fetch(:organisation_slug)
          ),
        }.merge(dependencies.except(:organisation_slug))
      )
    }
  }

  define_singleton(:edition_factory) { DocumentRecord::Edition.method(:new) }

  define_factory(:cma_case_builder) {
    CmaCaseBuilder.new(
      factory: get(:validatable_cma_case_factory),
      id_generator: IdGenerator,
    )
  }

  define_factory(:validatable_cma_case_factory) {
    ->(*args) {
      SlugUniquenessValidator.new(
        get(:cma_case_repository),
        CmaCaseValidator.new(
          CmaCase.new(
            SpecialistDocument.new(
              SlugGenerator.new(prefix: "cma-cases"),
              get(:edition_factory),
              *args,
            ),
          ),
        ),
      )
    }
  }

  define_factory(:aaib_report_builder) {
    AaibReportBuilder.new(
      factory: get(:validatable_aaib_report_factory),
      id_generator: IdGenerator,
    )
  }

  define_factory(:validatable_aaib_report_factory) {
    ->(*args) {
      SlugUniquenessValidator.new(
        get(:aaib_report_repository),
        AaibReportValidator.new(
          get(:aaib_report_factory).call(*args),
        ),
      )
    }
  }

  define_factory(:aaib_report_factory) {
    ->(*args) {
      AaibReport.new(
        SpecialistDocument.new(
          SlugGenerator.new(prefix: "aaib-reports"),
          get(:edition_factory),
          *args,
        )
      )
    }
  }

  define_factory(:international_development_fund_builder) {
    InternationalDevelopmentFundBuilder.new(
      factory: get(:validatable_international_development_fund_factory),
      id_generator: IdGenerator,
    )
  }

  define_factory(:validatable_international_development_fund_factory) {
    ->(*args) {
      SlugUniquenessValidator.new(
        get(:international_development_fund_repository),
        InternationalDevelopmentFundValidator.new(
          InternationalDevelopmentFund.new(
            SpecialistDocument.new(
              SlugGenerator.new(prefix: "international-development-funding"),
              get(:edition_factory),
              *args,
            )
          )
        )
      )
    }
  }

  define_factory(:manual_document_builder) {
    ManualDocumentBuilder.new(
      factory_factory: get(:validated_manual_document_factory_factory),
      id_generator: IdGenerator,
    )
  }

  define_factory(:validated_manual_document_factory_factory) {
    ->(manual) {
      ->(id, editions) {
        slug_generator = SlugGenerator.new(prefix: manual.slug)

        ChangeNoteValidator.new(
          # TODO: validate manual slugs
          ManualDocumentValidator.new(
            SpecialistDocument.new(
              slug_generator,
              get(:edition_factory),
              id,
              editions,
            ),
          )
        )
      }
    }
  }

  define_instance(:markdown_renderer) {
    SpecialistDocumentAttachmentProcessor.method(:new)
  }

  define_instance(:govspeak_html_converter) {
    ->(string) {
      Govspeak::Document.new(string).to_html
    }
  }

  define_instance(:govspeak_header_extractor) {
    ->(string) {
      Govspeak::Document.new(string).structured_headers
    }
  }

  define_instance(:specialist_document_govspeak_to_html_renderer) {
    ->(doc) {
      SpecialistDocumentGovspeakToHTMLRenderer.new(
        get(:govspeak_html_converter),
        doc,
      )
    }
  }

  define_instance(:specialist_document_govspeak_header_extractor) {
    ->(doc) {
      SpecialistDocumentHeaderExtractor.new(
        get(:govspeak_header_extractor),
        doc,
      )
    }
  }

  define_instance(:specialist_document_renderer) {
    ->(doc) {
      pipeline = [
        get(:markdown_renderer),
        get(:specialist_document_govspeak_header_extractor),
        get(:specialist_document_govspeak_to_html_renderer),
      ]

      pipeline.reduce(doc) { |doc, next_renderer|
        next_renderer.call(doc)
      }
    }
  }

  define_factory(:panopticon_registerer) {
    ->(artefact) {
      PanopticonRegisterer.new(
        mappings: PanopticonMapping,
        artefact: artefact,
        api: get(:panopticon_api),
        error_logger: Airbrake.method(:notify),
      ).call
    }
  }

  define_factory(:panopticon_api) {
    GdsApiProxy.new(
      GdsApi::Panopticon.new(
        Plek.current.find("panopticon"),
        PANOPTICON_API_CREDENTIALS
      )
    )
  }

  define_factory(:aaib_report_panopticon_registerer) {
    ->(document) {
      get(:panopticon_registerer).call(
        AaibReportArtefactFormatter.new(document)
      )
    }
  }

  define_factory(:cma_case_panopticon_registerer) {
    ->(document) {
      get(:panopticon_registerer).call(
        CmaCaseArtefactFormatter.new(document)
      )
    }
  }

  define_factory(:international_development_fund_panopticon_registerer) {
    ->(document) {
      get(:panopticon_registerer).call(
        InternationalDevelopmentFundArtefactFormatter.new(document)
      )
    }
  }

  define_factory(:manual_document_panopticon_registerer) {
    ->(document, manual) {
      get(:panopticon_registerer).call(
        ManualDocumentArtefactFormatter.new(document, manual)
      )
    }
  }

  define_factory(:manual_panopticon_registerer) {
    ->(manual) {
      get(:panopticon_registerer).call(
        ManualArtefactFormatter.new(manual)
      )

      get(:panopticon_registerer).call(
        ManualChangeNotesArtefactFormatter.new(manual)
      )

      manual.respond_to?(:documents) && manual.documents.each do |doc|
        get(:manual_document_panopticon_registerer).call(doc, manual)
      end
    }
  }

  define_factory(:aaib_report_rummager_indexer) {
    ->(document) {
      RummagerIndexer.new.add(
        AaibReportIndexableFormatter.new(
          SpecialistDocumentAttachmentProcessor.new(document)
        )
      )
    }
  }

  define_factory(:aaib_report_rummager_deleter) {
    ->(document) {
      RummagerIndexer.new.delete(
        AaibReportIndexableFormatter.new(
          SpecialistDocumentAttachmentProcessor.new(document)
        )
      )
    }
  }

  define_factory(:cma_case_rummager_indexer) {
    ->(document) {
      RummagerIndexer.new.add(
        CmaCaseIndexableFormatter.new(
          SpecialistDocumentAttachmentProcessor.new(document)
        )
      )
    }
  }

  define_factory(:cma_case_rummager_deleter) {
    ->(document) {
      RummagerIndexer.new.delete(
        CmaCaseIndexableFormatter.new(
          SpecialistDocumentAttachmentProcessor.new(document)
        )
      )
    }
  }

  define_factory(:international_development_fund_rummager_indexer) {
    ->(document) {
      RummagerIndexer.new.add(
        InternationalDevelopmentFundIndexableFormatter.new(
          SpecialistDocumentAttachmentProcessor.new(document)
        )
      )
    }
  }

  define_factory(:international_development_fund_rummager_deleter) {
    ->(document) {
      RummagerIndexer.new.delete(
        InternationalDevelopmentFundIndexableFormatter.new(
          SpecialistDocumentAttachmentProcessor.new(document)
        )
      )
    }
  }

  define_factory(:specialist_document_content_api_withdrawer) {
    ->(document) {
      RenderedSpecialistDocument.where(slug: document.slug).map(&:destroy)
    }
  }

  define_factory(:finder_api_withdrawer) {
    ->(doc) {
      get(:finder_api).notify_of_withdrawal(doc.slug)
    }
  }

  define_instance(:aaib_report_content_api_exporter) {
    ->(doc) {
      SpecialistDocumentDatabaseExporter.new(
        RenderedSpecialistDocument,
        get(:specialist_document_renderer),
        get(:aaib_report_finder_schema),
        doc,
      ).call
    }
  }

  define_instance(:cma_case_content_api_exporter) {
    ->(doc) {
      SpecialistDocumentDatabaseExporter.new(
        RenderedSpecialistDocument,
        get(:specialist_document_renderer),
        get(:cma_case_finder_schema),
        doc,
      ).call
    }
  }

  define_instance(:international_development_fund_content_api_exporter) {
    ->(doc) {
      SpecialistDocumentDatabaseExporter.new(
        RenderedSpecialistDocument,
        get(:specialist_document_renderer),
        get(:international_development_fund_finder_schema),
        doc,
      ).call
    }
  }

  define_factory(:manual_document_content_api_exporter) {
    ->(doc) {
      SpecialistDocumentDatabaseExporter.new(
        RenderedSpecialistDocument,
        get(:specialist_document_renderer),
        NullFinderSchema.new,
        doc,
      ).call
    }
  }

  define_factory(:manual_content_api_exporter) {
    ->(manual) {
      ManualDatabaseExporter.new(
        RenderedManual,
        manual,
      ).call
    }
  }

  define_factory(:manual_and_documents_content_api_exporter) {
    ->(manual) {

      get(:manual_content_api_exporter).call(manual)

      manual.documents.each do |exportable|
        get(:manual_document_content_api_exporter).call(exportable)
      end
    }
  }

  define_singleton(:finder_api) {
    FinderAPI.new(Faraday, Plek.current)
  }

  define_singleton(:finder_api_notifier) {
    FinderAPINotifier.new(get(:finder_api), get(:markdown_renderer))
  }

  define_singleton(:rummager_api) {
    GdsApi::Rummager.new(Plek.new.find("search"))
  }

  define_singleton(:aaib_report_finder_schema) {
    require "finder_schema"
    FinderSchema.new(Rails.root.join("schemas/aaib-reports.json"))
  }

  define_singleton(:cma_case_finder_schema) {
    require "finder_schema"
    FinderSchema.new(Rails.root.join("schemas/cma-cases.json"))
  }

  define_singleton(:international_development_fund_finder_schema) {
    require "finder_schema"
    FinderSchema.new(Rails.root.join("schemas/international-development-funds.json"))
  }

end
