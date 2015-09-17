Feature: Creating and editing a specialist document
  As an editor
  I want to create documents in specialist publisher
  So that I can add them to the specialist document finder

  Scenario Outline: Create a new document
    Given I am logged in as a "<organisation>" editor
    When I create a <document>
    Then the <document> has been created
    And the <document> should be in draft
    And the document should be sent to content preview
    And I should see a link to preview the document

    Examples:
      | organisation | document                         |
      | AAIB         | AAIB report                      |
      | CMA          | CMA case                         |
      | DEFRA        | Countryside Stewardship Grant    |
      | MHRA         | Drug Safety Update               |
      | DCLG         | ESI Fund                         |
      | MAIB         | MAIB report                      |
      | MHRA         | Medical Safety Alert             |
      | RAIB         | RAIB report                      |
      | DFID         | International Development Fund   |
      | DVSA         | Vehicle Recalls and Faults alert |

  Scenario Outline: Edit a draft document
    Given I am logged in as a "<organisation>" editor
    And a draft <document> exists
    When I edit a <document>
    Then the <document> should have been updated
    And the document should be sent to content preview

    Examples:
      | organisation | document                         |
      | AAIB         | AAIB report                      |
      | CMA          | CMA case                         |
      | DEFRA        | Countryside Stewardship Grant    |
      | MHRA         | Drug Safety Update               |
      | DCLG         | ESI Fund                         |
      | MAIB         | MAIB report                      |
      | MHRA         | Medical Safety Alert             |
      | RAIB         | RAIB report                      |
      | DFID         | International Development Fund   |
      | DVSA         | Vehicle Recalls and Faults alert |
