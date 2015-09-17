Feature: Creating and editing a Drug Safety Update
  As a MHRA Editor
  I want to create a drug safety update in Specialist publisher
  So that I can add them to the Drug Safety Update finder

  Background:
    Given I am logged in as a "MHRA" editor

  Scenario: Can view a list of all Drug Safety Updates in the publisher
    Given two Drug Safety Updates exist
    Then the Drug Safety Updates should be in the publisher DSU index in the correct order
