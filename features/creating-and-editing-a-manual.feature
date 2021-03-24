Feature: Creating and editing a manual
  As an editor
  I want to create and edit a manual and see it in the publisher
  So that I can start moving my content to gov.uk

  Background:
    Given I am logged in as an editor

  Scenario: Create a new manual
    When I create a manual
    Then the manual should exist
    And the manual should have been sent to the draft publishing api
    And I should see a link to preview the manual

  Scenario: Edit a draft manual
    Given a draft manual exists without any sections
    When I edit a manual
    Then the manual should have been updated
    And the edited manual should have been sent to the draft publishing api

  Scenario: Checking publication state of a manual
    Given a draft manual exists with some sections
    Then the manual is listed as draft
    When I publish the manual
    Then the manual is listed as published
    When I edit the manual
    Then the manual is listed as published with new draft

  @javascript
  Scenario: Previewing a draft manual
    Given a draft manual exists without any sections
    When I make changes and preview the manual
    Then I see the manual body preview

  @javascript
  Scenario: Previewing a new manual
    When I start creating a new manual
    And I preview the manual
    Then I see the manual body preview

  @javascript
  Scenario: Previewing a manual with a body containing javascript
    When I start creating a new manual with embedded javascript
    And I preview the manual
    Then I should see an error message about a "Body" field containing javascript

  @regression
  Scenario: Create and edit a manual with sections
    Given a draft manual exists without any sections
    And a draft section exists for the manual
    When I edit a manual
    Then the manual's sections won't have changed

  Scenario: Try to create an invalid manual
    When I create a manual with an empty title
    Then I see errors for the title field

  Scenario: Try to create an invalid section
    Given a draft manual exists without any sections
    When I create a section with empty fields
    Then I see errors for the section fields

  Scenario: Add a section to a manual
    Given a draft manual exists without any sections
    When I create a section for the manual
    Then I see the manual has the new section
    And I see the section isn't visually expanded
    And the section and table of contents will have been sent to the draft publishing api

  Scenario: Add an expanded section to a manual
    Given a draft manual exists without any sections
    When I create an expanded section for the manual
    Then I see the manual has the new section
    And I see the section is visually expanded
    And the section and table of contents will have been sent to the draft publishing api

  Scenario: Edit a draft section on a manual
    Given a draft manual exists without any sections
    And a draft section exists for the manual
    When I edit the section
    Then the section should have been updated
    And the updated section at the new slug and updated table of contents will have been sent to the draft publishing api

  Scenario: Attach a file to a section
    Given a draft manual exists without any sections
    And a draft section exists for the manual
    When I attach a file and give it a title
    Then I see the attached file

  Scenario: Duplicating a manual title
    Given a draft manual exists without any sections
    When I create another manual with the same slug
    Then I see a warning about slug clash at publication

  Scenario: Duplicating a section title
    Given a draft manual exists without any sections
    And a draft section exists for the manual
    When I create a section with duplicate title
    Then I see a warning about section slug clash at publication

  @javascript
  Scenario: Previewing a draft section with an attachment
    Given a draft manual exists without any sections
    And a draft section exists for the manual
    When I attach a file and give it a title
    Then I see the attached file
    When I copy+paste the embed code into the body of the section
    And I preview the section
    Then I can see a link to the file with the title in the section preview

  @javascript
  Scenario: Previewing a new section
    Given a draft manual exists without any sections
    When I create a section to preview
    And I preview the section
    Then I see the section body preview

  @javascript
  Scenario: Previewing a manual with invalid HTML
    Given a draft manual exists without any sections
    When I create a section to preview
    And I add invalid HTML to the section body
    And I preview the section
    Then I should see an error message about a "Body" field containing javascript

  @javascript
  Scenario: Reordering manual sections
    Given a draft manual exists with some sections
    When I reorder the sections
    Then the order of the sections in the manual should have been updated
    And the new order should be visible in the preview environment

  Scenario: Editing a section
    Given a published manual exists
    When I edit one of the manual's sections
    Then I should see a link to preview the manual

  Scenario: Change notes on new sections
    Given a draft manual exists without any sections
    Then I can see the change note form when adding a new section

  Scenario: Change notes on published sections
    Given a published manual exists
    Then I can see the change note and update type form when editing existing sections
    And I can see the change note form when adding a new section
    When I create a section for the manual with a change note
    Then I can see the change note and update type form when editing existing sections
    And the change note form for the section contains my note
    When I publish the manual
    Then the section is published as a major update including a change note draft
    And I can see the change note and update type form when editing existing sections
    And the change note form for the section is clear

  Scenario: Creating a manual that was previously published elsewhere
    Given I create a manual that was previously published elsewhere
    When I publish the manual
    Then the manual and its sections are published with all public timestamps set to the previously published date
    When I publish a minor change to the manual
    Then the manual and its sections are republished with all public timestamps set to the previously published date
    When I publish a major change to the manual
    Then the manual and its sections are republished with all public timestamps set to the previously published date
    When I tell the manual to stop using the previously published date as the public date
    Then the manual and its sections are republished with the first published timestamp set to the previously published date, but not the public updated timestamp
    When I publish a major change to the manual
    Then the manual and its sections are republished with the first published timestamp set to the previously published date, but not the public updated timestamp
    When I update the previously published date to a new one
    Then the manual and its sections are republished with the first published timestamp set to the new published date, but not the public updated timestamp
    When I tell the manual to start using the previously published date as the public date
    Then the manual and its sections are republished with all public timestamps set to the new previously published date
    When I update the manual to clear the previously published date
    Then the manual and its sections are republished without any public timestamps
