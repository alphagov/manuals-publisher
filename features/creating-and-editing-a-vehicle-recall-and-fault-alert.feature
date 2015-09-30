Feature: Creating and editing a Vehicle Recalls and Faults alert
  As a DVSA Editor
  I want to create Vehicle Recalls and Faults alert pages in Specialist publisher
  So that I can add them to the Vehicle Recalls and Faults alert finder

  Background:
    Given I am logged in as a "DVSA" editor

  Scenario: Providing invalid inputs when editing an alert
    Given a draft Vehicle Recalls and Faults alert exists
    When I edit the Vehicle Recalls and Faults alert and remove summary
    Then the Vehicle Recalls and Faults alert should show an error for the summary
