Feature: Documentation within Manuals Publisher
  Scenario: What's new page
    Given I am logged in as an editor
    When I visit the homepage before November 2023
    And I click on "What's new"
    Then I can see what is new in Manuals Publisher
