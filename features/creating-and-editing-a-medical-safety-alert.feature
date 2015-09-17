Feature: Creating and editing a Medical Safety Alert
  As a MHRA Editor
  I want to create a Medical Safety Alert in Specialist publisher
  So that I can add them to the Drug Device Alert finder

  Background:
    Given I am logged in as a "MHRA" editor

  Scenario: Can view a list of all Medical Safety Alert in the publisher
    Given two Medical Safety Alerts exist
    Then the Medical Safety Alerts should be in the publisher MSA index in the correct order
