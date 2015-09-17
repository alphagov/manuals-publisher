Feature: Creating and editing an AAIB Report
  As an AAIB editor
  I want to create air investigation report pages in Specialist publisher
  So that I can add them to the AAIB reports finder

  Background:
    Given I am logged in as a "AAIB" editor

  Scenario: Can view a list of all AAIB reports in the publisher
    Given two AAIB reports exist
    Then the AAIB reports should be in the publisher report index in the correct order

