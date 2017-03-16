Feature: Attachments
  As an editor
  I want to upload an attachment to a case via the publisher
  So that users can access the supporting documents

  @regression
  Scenario: editor can add and replace attachment to manual
    Given I am logged in as an editor
    And a draft manual exists without any sections
    And a draft section exists for the manual
    When I attach a file and give it a title
    Then I see the attached file
    When I edit the attachment
    Then I see the updated attachment on the section edit page

  @regression
  Scenario: GDS editor can add attachment to manual from another Org
    Given a draft manual exists belonging to "ministry-of-tea"
    And I am logged in as a GDS editor
    And a draft section exists for the manual
    When I attach a file and give it a title
    Then I see the attached file
    When I edit the attachment
    Then I see the updated attachment on the section edit page
