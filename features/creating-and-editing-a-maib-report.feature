Feature: Publishing an MAIB Report
  As an MAIB editor
  I want to create a new report in draft
  So that I can prepare the info for publication

  Background:
    Given I am logged in as a "MAIB" editor

  Scenario: Can view a list of all MAIB reports in the publisher
    Given two MAIB reports exist
    Then the MAIB reports should be in the publisher report index in the correct order

