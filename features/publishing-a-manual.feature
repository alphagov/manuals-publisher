Feature: Publishing a manual
  As an editor
  I want to publish finished manuals
  So that they are available on GOV.UK

  Background:
    Given I am logged in as an editor

  Scenario: Publish a manual
    Given a draft manual exists with some sections
    When I publish the manual
    Then the manual and all its sections are published
    And I should see a link to the live manual

  Scenario: Edit and re-publish a manual
    Given a published manual exists
    When I edit one of the manual's sections
    Then the updated section is available to preview
    When I publish the manual
    Then the manual and the edited section are published
    And the sections that I didn't edit were not republished

  Scenario: Add a section to a published manual
    Given a published manual exists
    When I add another section to the manual
    And I publish the manual
    Then the manual and its new section are published

  Scenario: Add a change note
    Given a published manual exists
    When I create a section for the manual with a change note
    And I publish the manual
    Then the manual is published as a major update including a change note draft

  Scenario: Omit the change note
    Given a published manual exists
    Then I see no visible change note in the section edit form
    When I edit one of the manual's sections without a change note
    Then I see an error requesting that I provide a change note
    When I indicate that the change is minor
    Then the section is updated without a change note
    When I publish the manual
    Then the manual is published as a minor update including a change note draft

  Scenario: Minor changes are published as major for first editions
    Given a published manual exists
    # this happens outside the UI because it's no longer possible in the UI
    When I create a section for the manual as a minor change without the UI
    And I publish the manual
    Then the manual is published as a major update
    And the section is published as a major update
    When I edit one of the manual's sections as a minor change
    And I publish the manual
    Then the manual is published as a minor update including a change note draft
    And the section is published as a minor update including a change note draft

  Scenario: A manual fails to publish from the queue due to an unrecoverable error
    Given a draft manual exists without any sections
    And a draft section exists for the manual
    And an unrecoverable error occurs
    When I publish the manual
    Then the manual and its sections have failed to publish

  Scenario: A manual fails to publish from the queue due to a version mismatch
    Given a draft manual exists without any sections
    And a draft section exists for the manual
    And a version mismatch occurs
    When I publish the manual
    Then the manual and its sections have failed to publish

  @disable_background_processing
  Scenario: A manual has been queued to be published
    Given a draft manual exists without any sections
    And a draft section exists for the manual
    When I publish the manual
    Then the manual and its sections are queued for publishing

  Scenario: Manual publication retries after recoverable error
    Given a draft manual exists without any sections
    And a draft section exists for the manual
    And a recoverable error occurs
    When I publish the manual expecting a recoverable error
    Then the publication reattempted
