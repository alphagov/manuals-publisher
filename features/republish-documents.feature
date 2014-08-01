Feature: Script to republish published documents
  the `bin/rerender_published_documents` script should regenerate the
  RenderedSpecialistDocument for every published edition

  Scenario: Republish all published documents
    Given some published, withdrawn and draft specialist documents exist
    And their RenderedSpecialistDocument records are missing
    When I republish published documents 
    Then the documents should be republished with valid RenderedSpecialistDocuments
