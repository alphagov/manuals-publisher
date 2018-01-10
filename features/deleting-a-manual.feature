Feature: Rake task to delete a manual
  the `delete_draft_manual` Rake task should delete a given manual and all its
  sections and its slug is no longer reserved

  Background:
    Given I am logged in as an editor

  Scenario: Deleting a manual
    Given a draft manual exists without any sections
    And a draft section exists for the manual
    When I run the deletion script
    And I confirm deletion
    Then the manual and its sections are deleted

  Scenario: Deleting a manual from the UI
    Given a draft manual exists without any sections
    And a draft section exists for the manual
    When I discard the draft manual
    Then the manual and its sections are deleted

  Scenario: Deleting a published manual
    Given a published manual exists
    When I run the deletion script
    Then the script raises an error
    And the manual and its sections still exist
