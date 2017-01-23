Feature: Creating and editing a manual
  As a CMA editor
  I want to create and edit a manual and see it in the publisher
  So that I can start moving my content to gov.uk

  Background:
    Given I am logged in as a "CMA" editor

  Scenario: Create a new manual
    When I create a manual
    Then the manual should exist
    And the manual should have been sent to the draft publishing api
    And I should see a link to preview the manual

  Scenario: Edit a draft manual
    Given a draft manual exists without any documents
    When I edit a manual
    Then the manual should have been updated
    And the edited manual should have been sent to the draft publishing api

  @javascript
  Scenario: Previewing a draft manual
    Given a draft manual exists without any documents
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
  Scenario: Create and edit a manual with documents
    Given a draft manual exists without any documents
    And a draft document exists for the manual
    When I edit a manual
    Then the manual's documents won't have changed

  Scenario: Try to create an invalid manual
    When I create a manual with an empty title
    Then I see errors for the title field

  Scenario: Try to create an invalid manual document
    Given a draft manual exists without any documents
    When I create a document with empty fields
    Then I see errors for the document fields

  Scenario: Add a document to a manual
    Given a draft manual exists without any documents
    When I create a document for the manual
    Then I see the manual has the new section
    And the manual document and table of contents will have been sent to the draft publishing api

  Scenario: Edit a draft document on a manual
    Given a draft manual exists without any documents
    And a draft document exists for the manual
    When I edit the document
    Then the document should have been updated
    And the updated manual document at the new slug and updated table of contents will have been sent to the draft publishing api

  Scenario: Attach a file to a manual document
    Given a draft manual exists without any documents
    And a draft document exists for the manual
    When I attach a file and give it a title
    Then I see the attached file

  Scenario: Duplicating a manual title
    Given a draft manual exists without any documents
    When I create another manual with the same slug
    Then I see a warning about slug clash at publication

  Scenario: Duplicating a section title
    Given a draft manual exists without any documents
    And a draft document exists for the manual
    When I create a section with duplicate title
    Then I see a warning about section slug clash at publication

  @javascript
  Scenario: Previewing a draft manual document with an attachment
    Given a draft manual exists without any documents
    And a draft document exists for the manual
    When I attach a file and give it a title
    Then I see the attached file
    When I copy+paste the embed code into the body of the document
    And I preview the document
    Then I can see a link to the file with the title in the document preview

  @javascript
  Scenario: Previewing a new manual document
    Given a draft manual exists without any documents
    When I create a document to preview
    And I preview the document
    Then I see the document body preview

  @javascript
  Scenario: Previewing a manual with invalid HTML
    Given a draft manual exists without any documents
    When I create a document to preview
    And I add invalid HTML to the document body
    And I preview the document
    Then I should see an error message about a "Body" field containing javascript

  @javascript
  Scenario: Reordering manual sections
    Given a draft manual exists with some documents
    When I reorder the documents
    Then the order of the documents in the manual should have been updated
    And the new order should be visible in the preview environment

  Scenario: Editing a manual document
    Given a published manual exists
    When I edit one of the manual's documents
    Then I should see a link to preview the manual

  Scenario: Change notes on new manual documents
    Given a draft manual exists without any documents
    Then I can see the change note form when adding a new section

  Scenario: Change notes on published manual documents
    Given a published manual exists
    Then I can see the change note and update type form when editing existing sections
    And I can see the change note form when adding a new section
    When I create a document for the manual with a change note
    Then I can see the change note and update type form when editing existing sections
    And the change note form for the document contains my note
    When I publish the manual
    Then the section is published as a major update including a change note draft
    And I can see the change note and update type form when editing existing sections
    And the change note form for the document is clear

  Scenario: Creating a manual that was previously published elsewhere
    Given I create a manual that was previously published elsewhere
    And a draft document exists for the manual
    When I publish the manual
    Then the manual is published with first published at and public updated at dates set to the previously published date
    And the document is published with first published at and public updated at dates set to the previously published date
