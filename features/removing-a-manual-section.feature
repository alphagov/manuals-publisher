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
    And the removed document is archived

  Scenario: Removing a draft section as an editor
    Given I am logged in as a "CMA" editor
    And a draft manual exists without any documents
    And a draft document exists for the manual
    When I remove the document from the manual
    Then the document is removed from the manual
    When I add another section and publish the manual later
    Then the removed document is not published
    And the removed document is archived

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
    And the removed document is archived

  Scenario: Removing a previously published section from a draft manual as an editor
    Given I am logged in as a "CMA" editor
    And a published manual exists
    And I edit one of the manual's documents
    When I remove the edited document from the manual
    Then the document is removed from the manual
    When I publish the manual
    Then the removed document is not published
    But the removed document is withdrawn with a redirect to the manual
    And the removed document is archived

  Scenario: Removing a previously published section from a draft manual as an editor
    Given I am logged in as a writer
    And a published manual with some sections was created without the UI
    And I edit one of the manual's documents
    Then I cannot remove a document from the manual

  Scenario: Removing a section from a published manual as a GDS editor
    Given I am logged in as a "GDS" editor
    And a published manual exists
    When I remove one of the documents from the manual
    Then the document is removed from the manual
    When I publish the manual
    Then the removed document is not published
    But the removed document is withdrawn with a redirect to the manual
    And the removed document is archived

  Scenario: Removing a section from a published manual as an editor
    Given I am logged in as a "CMA" editor
    And a published manual exists
    When I remove one of the documents from the manual
    Then the document is removed from the manual
    When I publish the manual
    Then the removed document is not published
    But the removed document is withdrawn with a redirect to the manual
    And the removed document is archived

  Scenario: Removing a section from a published manual as an editor
    Given I am logged in as a writer
    And a published manual with some sections was created without the UI
    Then I cannot remove a document from the manual

  Scenario: Removing a section with a major update change notes
    Given I am logged in as a "GDS" editor
    And a published manual exists
    When I remove one of the documents from the manual with a major update omitting the note
    Then I see an error requesting that I provide a change note
    When I remove one of the documents from the manual with a major update
    Then the document is removed from the manual
    When I publish the manual
    # TODO: we publish twice to work around change note publishing bug
    And I add another section and publish the manual later
    Then the removed document change note is included

  Scenario: Removing a section with a minor update change notes
    Given I am logged in as a "GDS" editor
    And a published manual exists
    When I remove one of the documents from the manual with a minor update
    Then the document is removed from the manual
    When I publish the manual
    # TODO: we publish twice to work around change note publishing bug
    And I add another section and publish the manual later
    Then the removed document change note is not included
