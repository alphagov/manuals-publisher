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
    When I add another section and publish the manual later
    Then the removed document is not published

  Scenario: Removing a draft section as an editor
    Given I am logged in as a "CMA" editor
    And a draft manual exists without any documents
    And a draft document exists for the manual
    When I remove the document from the manual
    Then the document is removed from the manual
    When I add another section and publish the manual later
    Then the removed document is not published

  Scenario: Removing a draft section as an editor
    Given I am logged in as a writer
    And a draft manual exists with some documents
    Then I cannot remove a document from the manual

  Scenario: Removing a previously published section from a draft manual as a GDS editor
    Given I am logged in as a "GDS" editor
    And a published manual exists
    And I edit one of the manual's documents
    When I remove the edited document from the manual
    Then the document is removed from the manual
    When I publish the manual
    Then the removed document is not published
    But the removed document is withdrawn with a redirect to the manual

  Scenario: Removing a previously published section from a draft manual as an editor
    Given I am logged in as a "CMA" editor
    And a published manual exists
    And I edit one of the manual's documents
    When I remove the edited document from the manual
    Then the document is removed from the manual
    When I publish the manual
    Then the removed document is not published
    But the removed document is withdrawn with a redirect to the manual

  Scenario: Removing a previously published section from a draft manual as an editor
    Given I am logged in as a writer
    And a published manual with some sections was created without the UI
    And I edit one of the manual's documents
    Then I cannot remove a document from the manual
