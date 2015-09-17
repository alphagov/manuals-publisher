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

  Scenario Outline: Cannot create a <document> with invalid fields
    Given I am logged in as a "<organisation>" editor
    When I create a <document> with invalid fields
    Then I should see error messages about missing fields
    Then I should see an error message about an invalid date field "<date_name>"
    And I should see an error message about a "Body" field containing javascript
    And the <document> should not have been created

    Examples:
      | organisation | document                         | date_name          |
      | AAIB         | AAIB report                      | Date of occurrence |
      | CMA          | CMA case                         | Opened date        |
      | DEFRA        | Countryside Stewardship Grant    | N/A                |
      | MHRA         | Drug Safety Update               | N/A                |
      | DCLG         | ESI Fund                         | N/A                |
      | MAIB         | MAIB report                      | Date of occurrence |
      | MHRA         | Medical Safety Alert             | Issued date        |
      | RAIB         | RAIB report                      | Date of occurrence |
      | DFID         | International Development Fund   | N/A                |
      | DVSA         | Vehicle Recalls and Faults alert | Alert issue date   |

  Scenario Outline: Cannot edit an <document> without entering required fields
    Given I am logged in as a "<organisation>" editor
    Given a draft <document> exists
    When I edit an <document> and remove required fields
    Then the <document> should not have been updated

    Examples:
      | organisation | document                         |
      | AAIB         | AAIB report                      |
      | DEFRA        | Countryside Stewardship Grant    |
      | DCLG         | ESI Fund                         |
      | MAIB         | MAIB report                      |
      | RAIB         | RAIB report                      |
      | DFID         | International Development Fund   |
