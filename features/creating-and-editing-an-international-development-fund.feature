Feature: Creating and editing an International Development Fund
  As a DFID Editor
  I want to create international development fund pages in Specialist publisher
  So that I can add them to the International Development Funds finder

  Background:
    Given I am logged in as a "DFID" editor

  Scenario: Can view a list of all International Development Funds in the publisher
    Given two International Development Funds exist
    Then the International Development Funds should be in the publisher IDF index in the correct order
