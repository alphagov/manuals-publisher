# Next steps

## Bugs

While refactoring the app we have discovered a [number of bugs](https://github.com/alphagov/manuals-publisher/issues?q=is%3Aopen+is%3Aissue+label%3Abug). We have also converted Errbit exceptions and reports from users into bugs in the Github issue tracker. These should be easier to fix now the application is in a simpler state. When fixing these be mindful that some may be easier to fix (or become redundant) if the app is "fully migrated" (see next section).

## Rely solely on the Publishing API for persistence

There is an ambition to refactor all publishing applications such that they solely rely on external APIs for persistence. Currently the [specialist publisher]() application is an example of an application that has been "fully migrated".

Currently Manuals Publisher is not fully migrated. It stores state in its own MongoDB database and publishes via the Publishing API.

As discussed above, one of the harder things to understand about this application is the separation between domain models and persistence (for example between `Manual` and `ManualRecord`).

A future refactoring that fully migrates this application would mean that local persistence is removed (and therefore the persistence classes such as `ManualRecord` could be removed).

We began a spike into this approach and it seems feasible. We have [added some notes](full-migrated-spike.md) about the spike and some potential pain points.

The work to date on this is tracked under the [Publishing API](https://github.com/alphagov/manuals-publisher/milestone/6) milestone in Github.

## Refactor test suite

There are a number of changes to the test suite that would make future refactoring (and adding features) easier. In particular:

- [Choosing either Cucumber or RSpec](https://github.com/alphagov/manuals-publisher/issues/879) for feature tests, rather than using both.
- [Shorten the time it takes to run the suite](https://github.com/alphagov/manuals-publisher/issues/1015) by adopting a better "test pyramid".

We have captured these and other improvements in the [Testing](https://github.com/alphagov/manuals-publisher/milestone/5) milestone.

## Replace Rake tasks with features

There are some [Rake Tasks](../lib/tasks/) which can be replaced with features in the User Interface. This would allow an organisation editor (or a admin role) to achieve their aim without having to involve a developer. The following Rake tasks are suitable candidates for converting to features:

- [delete_draft_manual.rake](../lib/tasks/delete_draft_manual.rake)
- [relocate_manual.rake](../lib/tasks/relocate_manual.rake)
- [reslug_section.rake](../lib/tasks/reslug_section.rake)
- [withdraw_manual.rake](../lib/tasks/withdraw_manual.rake)
