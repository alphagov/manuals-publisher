Feature: View and edit a manual's change history
  Background:
    Given I am logged in as an editor

  Scenario: Removing a change note from a manual's change history
    Given a published manual exists
    When I visit the change history page for the manual
    Then I see the change notes for the manual