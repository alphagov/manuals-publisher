Feature: Creating and editing an Countryside Stewardship Grant
As a DEFRA Editor
I want to create countryside stewardship grants pages in Specialist publisher
So that I can add them to the Countryside Stewardship Grants finder

Background:
Given I am logged in as a "DEFRA" editor

Scenario: Cannot create a Countryside Stewardship Grant with invalid fields
  When I create a Countryside Stewardship Grant with invalid fields
  Then I should see error messages about missing fields
  And I should see an error message about a "Body" field containing javascript
  And the Countryside Stewardship Grant should not have been created

Scenario: Cannot edit an Countryside Stewardship Grant without entering required fields
  Given a draft Countryside Stewardship Grant exists
  When I edit an Countryside Stewardship Grant and remove required fields
  Then the Countryside Stewardship Grant should not have been updated

Scenario: Can view a list of all Countryside Stewardship Grants in the publisher
  Given two Countryside Stewardship Grants exist
  Then the Countryside Stewardship Grants should be in the publisher CSG index in the correct order
