Feature: Viewing specialist documents
  As an editor
  I want to view documents in specialist publisher
  So that I select a specialist document to work on

  Scenario Outline: Can view a list of all documents in the publisher
    Given I am logged in as a "<organisation>" editor
    Given two <documents> exist
    Then the <documents> should be in the publisher document index in the correct order

    Examples:
      | organisation | documents                         |
      | AAIB         | AAIB reports                      |
      | AST          | "Asylum support decisions"        |
      | CMA          | CMA cases                         |
      | DEFRA        | Countryside Stewardship Grants    |
      | MHRA         | Drug Safety Updates               |
      | DCLG         | ESI Funds                         |
      | MAIB         | MAIB reports                      |
      | MHRA         | Medical Safety Alerts             |
      | RAIB         | RAIB reports                      |
      | DFID         | International Development Funds   |
      | DVSA         | Vehicle Recalls and Faults alerts |
      | UTAAC        | "UTAAC decisions"                 |
