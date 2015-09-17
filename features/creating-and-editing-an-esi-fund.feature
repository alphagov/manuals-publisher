Feature: Creating and editing an ESI Fund
As a DCLG Editor
I want to create ESI Funds pages in Specialist publisher
So that I can add them to the ESI Funds finder

Background:
Given I am logged in as a "DCLG" editor

Scenario: Can view a list of all ESI Funds in the publisher
  Given two ESI Funds exist
  Then the ESI Funds should be in the publisher CSG index in the correct order
