# Manuals Publisher Edition Workflow

Manuals have a complex workflow because both they and the sections they contain may have multiple editions. This makes reasoning about sections particularly difficult because some changes to the section edition state are only applied at the time the manual edition is published. This is particularly true in the case of withdrawing a section, where the section will be in the `removed_sections` list for the manual edition but will have a state of `published` until the manual edition is published. Even though the section still has the `published` state, it will not be visible in the user interface when editing the manual. Note that Manuals Publisher uses the terms `withdrawn` and `archived` interchangeably.

The other surprising aspect of Manuals Publisher workflow is that, unlike many other GOV.UK Publishing applications, there isn't a user interaction that explicitly creates a new edition of a manual or section. Instead new editions of both sections and manuals are created implicitly when a section is edited and saved.

As you can see below, the state machines themselves are relatively simple but understanding the interaction between them is tricky.

```mermaid
---
title: Manual State Diagram
---
stateDiagram-v2
    [*] --> Draft: Create new manual
    Draft --> Published: Publish manual
    Published --> Archived: Withdraw manual
    Published --> Draft: Modify section or update manual
    
    note right of Draft
        Once a manual has been published,
        editing the manual content or any section
        implicitly creates a new draft edition of the manual
    end note
    
    note right of Archived
        Manuals can only be archived using a rake task.
    end note
```

```mermaid
---
title: Section State Diagram
---
stateDiagram-v2
    [*] --> Draft: Create new section
    Draft --> Published: Publish manual
    Draft --> Archived: Withdraw section and publish manual
    Published --> Archived: Withdraw section and publish manual
    Published --> Draft: Edit section content
    
    note right of Draft
        Editing any section content implicitly creates a new draft of the section.
    end note
    
    note right of Published
        Sections cannot be published independently.
        Draft sections transition to published when the manual is published.
    end note
    
    note right of Archived
        Withdrawing a section via the UI moves the section UUID to the manual edition's 'removed_sections' list.
        Published or draft sections in the 'removed_sections' list are transitioned to archived when the manual is published.
    end note
```
