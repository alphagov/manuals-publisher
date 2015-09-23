Feature: Creating and editing a Medical Safety Alert
  As a MHRA Editor
  I want to create a Medical Safety Alert in Specialist publisher
  So that I can add them to the Drug Device Alert finder

  Background:
    Given I am logged in as a "MHRA" editor

  Scenario: Cannot create a Medical Safety Alert with invalid fields
    When I create a Medical Safety Alert with invalid fields
    Then I should see error messages about missing fields
    And I should see an error message about a "Body" field containing javascript
    And the Medical Safety Alert should not have been created

  Scenario: Cannot edit a Medical Safety Alert without entering required fields
    Given a draft Medical Safety Alert exists
    When I edit a Medical Safety Alert and remove required fields
    Then the Medical Safety Alert should not have been updated

  Scenario: Can view a list of all Medical Safety Alert in the publisher
    Given two Medical Safety Alerts exist
    Then the Medical Safety Alerts should be in the publisher MSA index in the correct order
