Feature: Removing a section from a manual
  As an editor or gds editor
  I want to remove a section from a manual
  So that it no longer one of the manual's sections

  Scenario: Removing a draft section as a GDS editor
    Given I am logged in as a GDS editor
    And a draft manual exists without any sections
    And a draft section exists for the manual
    When I remove the section from the manual
    Then the section is removed from the manual
    When I add another section and publish the manual later
    Then the removed section is not published
    And the removed section is archived

  Scenario: Removing a draft section as an editor
    Given I am logged in as an editor
    And a draft manual exists without any sections
    And a draft section exists for the manual
    When I remove the section from the manual
    Then the section is removed from the manual
    When I add another section and publish the manual later
    Then the removed section is not published
    And the removed section is archived

  Scenario: Removing a draft section as an editor
    Given I am logged in as a writer
    And a draft manual exists with some sections
    Then I cannot remove a section from the manual

  Scenario: Removing a previously published section from a draft manual as a GDS editor
    Given I am logged in as a GDS editor
    And a published manual exists
    And I edit one of the manual's sections
    When I remove the edited section from the manual
    Then the section is removed from the manual
    When I publish the manual
    Then the removed section is not published
    But the removed section is withdrawn with a redirect to the manual
    And the removed section is archived

  Scenario: Removing a previously published section from a draft manual as an editor
    Given I am logged in as an editor
    And a published manual exists
    And I edit one of the manual's sections
    When I remove the edited section from the manual
    Then the section is removed from the manual
    When I publish the manual
    Then the removed section is not published
    But the removed section is withdrawn with a redirect to the manual
    And the removed section is archived

  Scenario: Removing a previously published section from a draft manual as an editor
    Given I am logged in as a writer
    And a published manual with some sections was created without the UI
    And I edit one of the manual's sections
    Then I cannot remove a section from the manual

  Scenario: Removing a section from a published manual as a GDS editor
    Given I am logged in as a GDS editor
    And a published manual exists
    When I remove one of the sections from the manual
    Then the section is removed from the manual
    When I publish the manual
    Then the removed section is not published
    But the removed section is withdrawn with a redirect to the manual
    And the removed section is archived

  Scenario: Removing a section from a published manual as an editor
    Given I am logged in as an editor
    And a published manual exists
    When I remove one of the sections from the manual
    Then the section is removed from the manual
    When I publish the manual
    Then the removed section is not published
    But the removed section is withdrawn with a redirect to the manual
    And the removed section is archived

  Scenario: Removing a section from a published manual as an editor
    Given I am logged in as a writer
    And a published manual with some sections was created without the UI
    Then I cannot remove a section from the manual

  Scenario: Removing a section with a major update change notes
    Given I am logged in as a GDS editor
    And a published manual exists
    When I remove one of the sections from the manual with a major update omitting the note
    Then I see an error requesting that I provide a change note
    When I remove one of the sections from the manual with a major update
    Then the section is removed from the manual
    When I add another section and publish the manual later
    Then the removed section change note is included

  Scenario: Removing a section with a minor update change notes
    Given I am logged in as a GDS editor
    And a published manual exists
    When I remove one of the sections from the manual with a minor update
    Then the section is removed from the manual
    When I add another section and publish the manual later
    Then the removed section change note is not included
