Feature: Creating and editing a CMA case
  As a CMA editor
  I want to create and edit a case and see it in the publisher
  So that I can start moving my content to gov.uk

  Background:
    Given I am logged in as a "CMA" editor

  Scenario: Create a CMA case with a clashing slug
    Given a published CMA case exists
    When I create another case with the same slug
    Then I see a warning about slug clash at publication

  Scenario: Change the title of a previously published document
    Given a published CMA case exists
    When I change the CMA case title and re-publish
    Then the title has been updated
    And the URL slug remains unchanged

  @javascript
  Scenario: Previewing a draft CMA case
    Given a draft CMA case exists
    When I make changes and preview the CMA case
    Then I see the case body preview

  @javascript
  Scenario: Previewing a new CMA case
    When I start creating a new CMA case
    And I preview the case
    Then I see the case body preview

  @javascript
  Scenario: Previewing a CMA case with a body containing javascript
    When I start creating a new CMA case with embedded javascript
    And I preview the case
    Then I should see an error message about a "Body" field containing javascript
