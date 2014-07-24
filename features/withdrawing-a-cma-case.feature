Feature: Withdrawing a CMA case
  As a CMA editor
  I want to withdraw a CMA case
  So that it is not accessible to the public

  Background:
    Given I am logged in as a "CMA" editor

  Scenario: Withdraw a CMA case
    Given a published CMA case exists
    When I withdraw the CMA case
    Then the CMA case should be withdrawn

  Scenario: Withdraw a CMA case with a draft
    Given a published CMA case exists
    When I edit the CMA case
    And I withdraw the CMA case
    Then the CMA case should be withdrawn with a new draft
