Feature: Removing a section from a manual
  As an editor or gds editor
  I want to remove a section from a manual
  So that it no longer one of the manual's sections

  Scenario: Removing a draft section as a GDS editor
    Given I am logged in as a "GDS" editor
    And a draft manual exists without any documents
    And a draft document exists for the manual
    When I remove the document from the manual
    Then the document is removed from the manual

  Scenario: Removing a draft section as an editor
    Given I am logged in as a "CMA" editor
    And a draft manual exists without any documents
    And a draft document exists for the manual
    When I remove the document from the manual
    Then the document is removed from the manual
