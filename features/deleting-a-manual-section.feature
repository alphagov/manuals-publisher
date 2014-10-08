Feature: Ability to delete a manual section
  As a developer
  Because the rails console sucks
  I want to delete manual sections

  Background:
    Given I am logged in as a "CMA" editor

  Scenario: Deleting a manual document
    Given a draft manual exists
    And a draft document exists for the manual
    When I delete the document
    Then the document is deleted

  Scenario: Deleting a published manual document
    Given a published manual exists
    When I delete the document
    Then an error is raised
    And the document is not deleted
