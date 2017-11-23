# Rake tasks

## Deleting or removing draft manuals

### Deleting a draft manual

If a manual has been created in draft but never published it can be deleted using a rake task to delete draft manuals:

```
rake delete_draft_manual[manual-slug,manual-id]
```

This would need to be run using Jenkins on one of the backend boxes.


## Managing section slugs

Section slugs are automatically generated from the section title
when the section is initially created. Subsequent updates to the title
do not amend the slug. This is particularly obvious where the title was
given a numerical prefix eg. `1. The first chapter` which generates the
slug `1-the-first-chapter`.
It's not uncommon for editors to need to reorder the sections which
often leaves sections with numeric prefixes out of sync with their titles.
There are a couple of rake tasks which can help with this issue:

### Reporting on section slugs

```
rake sections:report[manual_slug]
```

This task will identify slugs which no longer match their titles (where a
match is a slug identical to the slugified title).
The output will list:
- Conflicts: slug updates which cannot be applied because
the destination slug is already in use.
- Amendments: slug updates which can be applied.

### Synchronising section slugs

```
rake sections:synchronise[manual_slug]
```

This task will update the slugs of sections which have no conflicts as
identified by the reporting task. Conflicts will be skipped, these will
need to be resolved manually.

### Update a section slug

```
rake reslug_section[manual_slug,old_section_slug,new_section_slug]
```

This task will update a single section slug, this performs an update within
the Manual Publisher application database and the Publishing API.

## Relocating Manuals

NOTE. The behaviour of this script is a little confusing (essentially overwriting one published manual with another) so it's not entirely obvious that it's still required.

```
rake relocate_manual[from_slug,to_slug]
```

Given the published manuals /guidance/manual-1 and /guidance/manual-2, this script will remove /guidance/manual-2 and update the manual and section slugs of /guidance/manual-1 to /guidance/manual-2.
