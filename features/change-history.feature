Feature: View and edit a manual's change history
  Background:
    Given I am logged in as a GDS editor

  Scenario: Removing a change note from a manual's change history
    Given a published manual exists
    When I visit the change history page for the manual
    Then I see the change notes for the manual
    When I click delete on a change note
    Then I am redirected to the confirmation page
    When I click the cancel button
    Then I am redirected to the Change history page
    And I can see that no change notes have been deleted
    When I click delete on a change note
    Then I am redirected to the confirmation page
    When I delete the change note
    Then I am redirected to the Change history page
    And I can see that the change note has been deleted
