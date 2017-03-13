Feature: Script to withdraw published manuals
  As a DevOps specialist
  I want to withdraw a manual
  So that it is not accessible to the public

  Background:
    Given I am logged in as an editor

  Scenario:
    Given a published manual exists
    When a DevOps specialist withdraws the manual for me
    Then the manual should be withdrawn
