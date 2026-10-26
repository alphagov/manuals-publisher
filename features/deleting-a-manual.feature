Feature: Rake task to delete a manual
  the `delete_draft_manual` Rake task should delete a given manual and all its
  sections and its slug is no longer reserved. If the manual has been
  published, only its draft is discarded.

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
    And I confirm draft deletion
    Then the manual and its sections are deleted

  Scenario: Discarding the draft of a published manual
    Given a published manual exists
    And I edit one of the manual's sections
    When I run the deletion script
    And I confirm deletion
    Then the draft of the manual and the edited section are discarded
    And the manual is listed as published

  Scenario: Discarding the draft of a published manual from the UI
    Given a published manual exists
    And I edit one of the manual's sections
    When I discard the draft manual
    And I confirm draft deletion
    Then the draft of the manual and the edited section are discarded
    And the manual is listed as published

  Scenario: Deleting a published manual without a draft
    Given a published manual exists
    When I run the deletion script
    Then the script raises an error
    And the manual and its sections still exist
