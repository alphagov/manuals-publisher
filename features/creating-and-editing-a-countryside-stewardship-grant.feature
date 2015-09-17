Feature: Creating and editing an Countryside Stewardship Grant
As a DEFRA Editor
I want to create countryside stewardship grants pages in Specialist publisher
So that I can add them to the Countryside Stewardship Grants finder

Background:
Given I am logged in as a "DEFRA" editor

Scenario: Can view a list of all Countryside Stewardship Grants in the publisher
  Given two Countryside Stewardship Grants exist
  Then the Countryside Stewardship Grants should be in the publisher CSG index in the correct order
