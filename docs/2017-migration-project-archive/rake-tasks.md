# Rake tasks

## Withdraw and redirect manuals

A manual can be withdrawn and redirected to another page on www.gov.uk.

There are a few rake tasks, depending on the requirements.

### Withdraw and redirect a single manual which can include its sections

The last two boolean arguments flag whether to include sections and discard
drafts, respectively.

```
withdraw_and_redirect_manual[guidance/manual,/redirect/blah,true,true]
```

### Withdraw and redirect a single section

The last boolean argument flags whether to discard drafts.

```
withdraw_and_redirect_section[guidance/manual,guidance/manual/section,/redirect/blah,true]
```

### Bulk withdraw and redirect multiple manuals and sections

If multiple manuals need to be redirected, or there are multiple redirect
destinations within manuals, e.g sections need to redirect to different places,
then we can do this by uploading a CSV and running the below tasks. Example CSV
PR: https://github.com/alphagov/manuals-publisher/pull/1895.

**Dry-run (checks all manuals exist in Manuals Publisher)**

```
withdraw_and_redirect_manuals_to_multiple_paths:dry_run[lib/tasks/path_to_csv.csv]
```

**Run the task for real**

The last boolean argument flags whether to discard drafts.

```
withdraw_and_redirect_manuals_to_multiple_paths:real[lib/tasks/path_to_csv.csv,true]
```

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

### Update organisation slug for manual records

```
rake reslug_organisation[old_slug,new_slug]
```

This is depended on by docs for [changing an organisation's slug](https://docs.publishing.service.gov.uk/manual/changing-organisation-slug.html#2-update-the-organisation-slug-in-manuals-publisher).

## Relocating Manuals

NOTE. The behaviour of this script is a little confusing (essentially overwriting one published manual with another) so it's not entirely obvious that it's still required.

```
rake relocate_manual[from_slug,to_slug]
```

Given the published manuals /guidance/manual-1 and /guidance/manual-2, this script will remove /guidance/manual-2 and update the manual and section slugs of /guidance/manual-1 to /guidance/manual-2.
