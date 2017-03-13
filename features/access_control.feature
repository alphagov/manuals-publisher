Feature: Access control
  As a User
  I want to have access only to relevant content
  So that I can publish content on gov.uk

  Scenario: Editor only sees manuals created by their organisation
    Given there are manuals created by multiple organisations
    And I am logged in as an editor
    When I view my list of manuals
    Then I only see manuals created by my organisation

  Scenario: GDS Editor sees manuals created by all organisations
    Given there are manuals created by multiple organisations
    And I am logged in as a GDS editor
    When I view my list of manuals
    Then I see manuals created by all organisations

  Scenario: Writers
    Given I am logged in as a writer
    Then I can edit manuals
    And I cannot publish manuals
